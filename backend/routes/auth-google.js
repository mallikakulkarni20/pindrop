// backend/routes/auth-google.js
import express from 'express';
import { OAuth2Client } from 'google-auth-library';
import jwt from 'jsonwebtoken';
import supabase from '../supabaseClient.js';

const router = express.Router();
const client = new OAuth2Client(
  process.env.GOOGLE_CLIENT_ID,
  process.env.GOOGLE_CLIENT_SECRET
);

const USER_SELECT =
  'user_id, name, email, home_location, budget_preference, travel_style, liked_tags, restaurant_meals_per_day, restaurant_meal_types, restaurant_cuisine_types, restaurant_dietary_restrictions, restaurant_min_price_range, restaurant_max_price_range, restaurant_custom_requests, created_at';

// Step 1: Redirect user to Google consent screen
router.get('/google', (req, res) => {
  const apiUrl = process.env.API_URL || `http://localhost:${process.env.PORT || 3001}`;
  const redirectUri = `${apiUrl}/api/auth/google/callback`;
  const authUrl = client.generateAuthUrl({
    access_type: 'offline',
    scope: ['profile', 'email'],
    prompt: 'consent',
    redirect_uri: redirectUri,
  });
  res.redirect(authUrl);
});

// Step 2: Google redirects here with ?code=...
router.get('/google/callback', async (req, res) => {
  try {
    const { code } = req.query;
    if (!code) {
      return res.redirect(`${process.env.FRONTEND_URL || 'http://localhost:5173'}/login?error=missing_code`);
    }

    const apiUrl = process.env.API_URL || `http://localhost:${process.env.PORT || 3001}`;
    const redirectUri = `${apiUrl}/api/auth/google/callback`;
    const { tokens } = await client.getToken({ code, redirect_uri: redirectUri });
    client.setCredentials({ access_token: tokens.access_token });

    const ticket = await client.verifyIdToken({
      idToken: tokens.id_token,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    const payload = ticket.getPayload();
    const { sub: oauthId, email, name } = payload;

    // Find existing user by OAuth
    const { data: existingUser, error: fetchError } = await supabase
      .from('app_user')
      .select(USER_SELECT)
      .eq('oauth_provider', 'google')
      .eq('oauth_id', oauthId)
      .maybeSingle();

    let user;
    let isNewUser = false;
    if (existingUser) {
      user = existingUser;
    } else {
      const { data: byEmail } = await supabase
        .from('app_user')
        .select('user_id')
        .eq('email', email)
        .maybeSingle();

      if (byEmail) {
        const { data: updated, error: updateError } = await supabase
          .from('app_user')
          .update({ oauth_provider: 'google', oauth_id: oauthId })
          .eq('user_id', byEmail.user_id)
          .select(USER_SELECT)
          .single();

        if (updateError) throw updateError;
        user = updated;
      } else {
        const { data: newUser, error: insertError } = await supabase
          .from('app_user')
          .insert([
            {
              name: name || email.split('@')[0],
              email,
              password_hash: null,
              oauth_provider: 'google',
              oauth_id: oauthId,
            },
          ])
          .select(USER_SELECT)
          .single();

        if (insertError) throw insertError;
        user = newUser;
        isNewUser = true;
      }
    }

    const token = jwt.sign(
      { userId: user.user_id, email: user.email },
      process.env.JWT_SECRET || 'your-super-secret-jwt-key-here',
      { expiresIn: '7d' }
    );

    const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:5173';
    const userJson = encodeURIComponent(JSON.stringify(user));
    const newUserParam = isNewUser ? '&newUser=1' : '';
    res.redirect(`${frontendUrl}/auth/callback?token=${token}&user=${userJson}${newUserParam}`);
  } catch (err) {
    console.error('Google OAuth error:', err);
    const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:5173';
    res.redirect(`${frontendUrl}/login?error=oauth_failed`);
  }
});

export default router;
