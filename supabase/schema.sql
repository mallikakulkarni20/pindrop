-- Pindrop DB schema (used for local Docker init)

-- Create trip status enum if needed
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'trip_status_type') THEN
        CREATE TYPE trip_status_type AS ENUM ('draft', 'planned', 'archived');
    END IF;
END$$;

CREATE TABLE IF NOT EXISTS app_user (
    user_id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    home_location VARCHAR(255),
    budget_preference DECIMAL(10, 2),
    travel_style VARCHAR(50),
    liked_tags TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

CREATE TABLE IF NOT EXISTS trip (
    trip_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES app_user(user_id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    destination VARCHAR(255),
    trip_status trip_status_type DEFAULT 'draft',
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

CREATE TABLE IF NOT EXISTS activity (
    activity_id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    location VARCHAR(255),
    city VARCHAR(255),
    address VARCHAR(255),
    category VARCHAR(100),
    duration VARCHAR(50),
    cost_estimate DECIMAL(10, 2),
    rating DECIMAL(3, 1),
    tags TEXT[] DEFAULT '{}',
    source VARCHAR(50),
    source_url TEXT,
    image_url TEXT,
    description TEXT,
    price_range VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

CREATE INDEX IF NOT EXISTS idx_activity_city ON activity(city);
CREATE INDEX IF NOT EXISTS idx_activity_location ON activity(location);

CREATE TABLE IF NOT EXISTS itinerary (
    itinerary_id BIGSERIAL PRIMARY KEY,
    trip_id BIGINT NOT NULL REFERENCES trip(trip_id) ON DELETE CASCADE,
    day_number INT NOT NULL,
    date DATE,
    summary TEXT,
    progress VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

CREATE TABLE IF NOT EXISTS itinerary_activity (
    itinerary_activity_id BIGSERIAL PRIMARY KEY,
    itinerary_id BIGINT NOT NULL REFERENCES itinerary(itinerary_id) ON DELETE CASCADE,
    activity_id BIGINT NOT NULL REFERENCES activity(activity_id) ON DELETE CASCADE,
    order_index INT,
    finalized BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Per-trip meal entries
CREATE TABLE IF NOT EXISTS trip_meal (
    trip_meal_id BIGSERIAL PRIMARY KEY,
    trip_id BIGINT NOT NULL REFERENCES trip(trip_id) ON DELETE CASCADE,
    day_number INT NOT NULL,
    slot VARCHAR(20) NOT NULL CHECK (slot IN ('breakfast', 'lunch', 'dinner')),
    name VARCHAR(255),
    location VARCHAR(255),
    link TEXT,
    image_url TEXT,
    cost DECIMAL(10, 2),
    finalized BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    UNIQUE (trip_id, day_number, slot)
);

-- Per-trip manual expenses
CREATE TABLE IF NOT EXISTS trip_expense (
    trip_expense_id BIGSERIAL PRIMARY KEY,
    trip_id BIGINT NOT NULL REFERENCES trip(trip_id) ON DELETE CASCADE,
    day_number INT NOT NULL,
    client_id TEXT NOT NULL,
    label VARCHAR(255) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    entered_amount DECIMAL(10, 2),
    currency_code VARCHAR(10) DEFAULT 'USD',
    category VARCHAR(20) NOT NULL CHECK (category IN ('activity', 'meal', 'hotel', 'transport', 'other')),
    finalized BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    UNIQUE (trip_id, client_id)
);

-- Trip-specific planning preferences
CREATE TABLE IF NOT EXISTS trip_preference (
    trip_preference_id BIGSERIAL PRIMARY KEY,
    trip_id BIGINT NOT NULL UNIQUE REFERENCES trip(trip_id) ON DELETE CASCADE,
    -- Core trip info
    num_days INT,
    start_date DATE,
    end_date DATE,
    -- Budget range
    min_budget DECIMAL(10, 2),
    max_budget DECIMAL(10, 2),
    -- Daily pace
    pace VARCHAR(50),
    -- Preferred stay type
    accommodation_type VARCHAR(50),
    -- Activity interests
    activity_categories TEXT[] DEFAULT '{}',
    -- Activities to avoid
    avoid_activity_categories TEXT[] DEFAULT '{}',
    -- Optional city focus list
    selected_cities TEXT[] DEFAULT '{}',
    -- Ordered cities for multi-city trips
    ordered_cities TEXT[] DEFAULT '{}',
    -- Day allocation per city (JSON)
    city_days JSONB,
    -- Multi-city step completion flag
    has_confirmed_multi_city BOOLEAN DEFAULT FALSE,
    -- Travel group type
    group_type VARCHAR(50),
    -- Safety/access notes
    safety_notes TEXT,
    accessibility_notes TEXT,
    -- Extra notes/constraints
    custom_requests TEXT,
    -- Restaurant preference JSON
    restaurant_preferences JSONB,
    -- Progress flags for planner flow
    has_confirmed_hotels BOOLEAN DEFAULT FALSE,
    has_confirmed_activities BOOLEAN DEFAULT FALSE,
    has_confirmed_restaurants BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Reusable restaurant catalog
CREATE TABLE IF NOT EXISTS restaurant (
    restaurant_id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    city VARCHAR(100),
    location VARCHAR(255),
    address VARCHAR(500),
    cuisine_type VARCHAR(100),
    meal_types TEXT[] DEFAULT '{}',
    dietary_options TEXT[] DEFAULT '{}',
    price_range VARCHAR(20),
    cost_estimate DECIMAL(10, 2),
    rating DECIMAL(3, 1),
    review_count INT,
    tags TEXT[] DEFAULT '{}',
    source VARCHAR(50),
    source_url TEXT,
    reservation_url TEXT,
    image_url TEXT,
    description TEXT,
    phone VARCHAR(50),
    hours TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Trip-level restaurant preference
CREATE TABLE IF NOT EXISTS trip_restaurant_preference (
    trip_restaurant_preference_id BIGSERIAL PRIMARY KEY,
    trip_id BIGINT NOT NULL REFERENCES trip(trip_id) ON DELETE CASCADE,
    restaurant_id BIGINT NOT NULL REFERENCES restaurant(restaurant_id) ON DELETE CASCADE,
    preference VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (preference IN ('pending', 'liked', 'disliked', 'maybe')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

CREATE INDEX IF NOT EXISTS idx_trip_restaurant_preference_trip_id ON trip_restaurant_preference(trip_id);
CREATE INDEX IF NOT EXISTS idx_restaurant_location ON restaurant(location);
CREATE INDEX IF NOT EXISTS idx_restaurant_city ON restaurant(city);

-- Trip-level activity preference
CREATE TABLE IF NOT EXISTS trip_activity_preference (
    trip_activity_preference_id BIGSERIAL PRIMARY KEY,
    trip_id BIGINT NOT NULL REFERENCES trip(trip_id) ON DELETE CASCADE,
    activity_id BIGINT NOT NULL REFERENCES activity(activity_id) ON DELETE CASCADE,
    preference VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (preference IN ('pending', 'liked', 'disliked', 'maybe')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

CREATE TABLE IF NOT EXISTS chat_message (
    message_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES app_user(user_id) ON DELETE CASCADE,
    trip_id BIGINT REFERENCES trip(trip_id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Flight options
CREATE TABLE IF NOT EXISTS flight (
    flight_id BIGSERIAL PRIMARY KEY,
    flight_type VARCHAR(20) NOT NULL CHECK (flight_type IN ('outbound', 'return', 'intercity')),
    -- Parsed from flight_data JSONB
    price DECIMAL(10, 2),
    departure_token VARCHAR(255), -- Used to fetch return flights
    total_duration INT, -- Minutes
    -- Nested JSON fields
    flights JSONB, -- Flight legs
    layovers JSONB, -- Layover info
    -- Extra flight payload
    additional_data JSONB, -- Misc fields
    -- Parsed from search_params JSONB
    departure_id VARCHAR(100), -- Departure airport code
    arrival_id VARCHAR(100), -- Arrival airport code
    outbound_date DATE,
    return_date DATE,
    currency VARCHAR(10) DEFAULT 'USD',
    -- Extra search params
    additional_search_params JSONB, -- Misc params
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Map flights to trips
CREATE TABLE IF NOT EXISTS trip_flight (
    trip_id BIGINT NOT NULL REFERENCES trip(trip_id) ON DELETE CASCADE,
    flight_id BIGINT NOT NULL REFERENCES flight(flight_id) ON DELETE CASCADE,
    -- Selected flight flag
    is_selected BOOLEAN DEFAULT FALSE,
    finalized BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    -- Composite PK
    PRIMARY KEY (trip_id, flight_id)
);

-- Valid return options for each outbound flight
CREATE TABLE IF NOT EXISTS flight_return_mapping (
    trip_id BIGINT NOT NULL REFERENCES trip(trip_id) ON DELETE CASCADE,
    departing_flight_id BIGINT NOT NULL REFERENCES flight(flight_id) ON DELETE CASCADE,
    return_flight_id BIGINT NOT NULL REFERENCES flight(flight_id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    -- Composite PK ensures uniqueness per trip
    PRIMARY KEY (trip_id, departing_flight_id, return_flight_id),
    -- Prevent self-mapping
    CONSTRAINT check_different_flights CHECK (departing_flight_id != return_flight_id)
);

CREATE INDEX IF NOT EXISTS idx_trip_user_id ON trip(user_id);
CREATE INDEX IF NOT EXISTS idx_itinerary_trip_id ON itinerary(trip_id);
CREATE INDEX IF NOT EXISTS idx_itinerary_activity_ids ON itinerary_activity(itinerary_id, activity_id);
CREATE INDEX IF NOT EXISTS idx_trip_preference_trip_id ON trip_preference(trip_id);
CREATE INDEX IF NOT EXISTS idx_chat_message_user_id ON chat_message(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_message_trip_id ON chat_message(trip_id);
CREATE INDEX IF NOT EXISTS idx_chat_message_created_at ON chat_message(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_trip_status ON trip(user_id, trip_status);
CREATE INDEX IF NOT EXISTS idx_trip_activity_preference_trip_id ON trip_activity_preference(trip_id);
CREATE INDEX IF NOT EXISTS idx_flight_type ON flight(flight_type);
CREATE INDEX IF NOT EXISTS idx_flight_departure_token ON flight(departure_token) WHERE departure_token IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_trip_flight_trip_id ON trip_flight(trip_id);
CREATE INDEX IF NOT EXISTS idx_trip_flight_flight_id ON trip_flight(flight_id);
-- App logic should enforce only one selected outbound + return
CREATE INDEX IF NOT EXISTS idx_trip_flight_selected ON trip_flight(trip_id, is_selected) WHERE is_selected = TRUE;
CREATE INDEX IF NOT EXISTS idx_flight_return_mapping_trip_id ON flight_return_mapping(trip_id);
CREATE INDEX IF NOT EXISTS idx_flight_return_mapping_departing ON flight_return_mapping(departing_flight_id);
CREATE INDEX IF NOT EXISTS idx_flight_return_mapping_return ON flight_return_mapping(return_flight_id);
CREATE INDEX IF NOT EXISTS idx_flight_return_mapping_trip_departing ON flight_return_mapping(trip_id, departing_flight_id);

-- Hotel options
CREATE TABLE IF NOT EXISTS hotel (
    hotel_id BIGSERIAL PRIMARY KEY,
    -- Basic hotel info
    name VARCHAR(255) NOT NULL,
    type VARCHAR(100), -- Example: hotel, vacation rental
    description TEXT,
    link TEXT, -- Property website
    logo TEXT, -- Logo URL
    sponsored BOOLEAN DEFAULT FALSE,
    eco_certified BOOLEAN DEFAULT FALSE,
    -- Location info
    location VARCHAR(255), -- Search location
    latitude DECIMAL(10, 8), -- From GPS coords
    longitude DECIMAL(11, 8), -- From GPS coords
    -- Check-in/out times
    check_in_time VARCHAR(50), -- Example: 3:00 PM
    check_out_time VARCHAR(50), -- Example: 12:00 PM
    -- Pricing fields
    rate_per_night_lowest DECIMAL(10, 2), -- Lowest nightly rate
    rate_per_night_formatted VARCHAR(50), -- Formatted value
    total_rate_lowest DECIMAL(10, 2), -- Lowest total rate
    total_rate_formatted VARCHAR(50), -- Formatted value
    -- Hotel class
    hotel_class VARCHAR(50), -- Example: 5-star hotel
    extracted_hotel_class INT, -- Example: 5
    -- Ratings
    overall_rating DECIMAL(3, 2), -- Example: 4.5
    reviews INT, -- Review count
    location_rating DECIMAL(3, 2), -- Location score
    -- Nested JSON fields
    prices JSONB, -- Price entries
    nearby_places JSONB, -- Nearby places/transit
    images JSONB, -- Image objects
    ratings JSONB, -- Star rating breakdown
    reviews_breakdown JSONB, -- Review category breakdown
    amenities TEXT[], -- Amenities
    excluded_amenities TEXT[], -- Excluded amenities
    health_and_safety JSONB, -- Health/safety JSON
    essential_info TEXT[], -- Essential rental info
    -- SerpAPI fields
    property_token VARCHAR(255), -- Property details token
    serpapi_property_details_link TEXT, -- SerpAPI details endpoint
    -- Search params
    search_location VARCHAR(255), -- Location searched
    check_in_date DATE, -- Search check-in date
    check_out_date DATE, -- Search check-out date
    currency VARCHAR(10) DEFAULT 'USD',
    -- Extra hotel payload
    additional_data JSONB, -- Misc hotel fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Map hotels to trips
CREATE TABLE IF NOT EXISTS trip_hotel (
    trip_id BIGINT NOT NULL REFERENCES trip(trip_id) ON DELETE CASCADE,
    hotel_id BIGINT NOT NULL REFERENCES hotel(hotel_id) ON DELETE CASCADE,
    -- Selected hotel flag
    is_selected BOOLEAN DEFAULT FALSE,
    finalized BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    -- Composite PK
    PRIMARY KEY (trip_id, hotel_id)
);

-- Hotel indexes
CREATE INDEX IF NOT EXISTS idx_hotel_location ON hotel(location);
CREATE INDEX IF NOT EXISTS idx_hotel_name ON hotel(name);
CREATE INDEX IF NOT EXISTS idx_hotel_property_token ON hotel(property_token) WHERE property_token IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_hotel_search_dates ON hotel(check_in_date, check_out_date);
CREATE INDEX IF NOT EXISTS idx_trip_hotel_trip_id ON trip_hotel(trip_id);
CREATE INDEX IF NOT EXISTS idx_trip_hotel_hotel_id ON trip_hotel(hotel_id);
-- App logic should enforce one selected hotel per trip
CREATE INDEX IF NOT EXISTS idx_trip_hotel_selected ON trip_hotel(trip_id, is_selected) WHERE is_selected = TRUE;

-- Cache hotel booking options from SerpAPI
CREATE TABLE IF NOT EXISTS hotel_booking_options (
    hotel_booking_options_id BIGSERIAL PRIMARY KEY,
    hotel_id BIGINT NOT NULL REFERENCES hotel(hotel_id) ON DELETE CASCADE,
    -- SerpAPI link used to fetch
    serpapi_link TEXT NOT NULL,
    -- Booking options payload
    booking_options_data JSONB NOT NULL,
    -- Fetch timestamp
    fetched_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    -- Avoid duplicates per hotel+link
    UNIQUE(hotel_id, serpapi_link)
);

-- Booking option indexes
CREATE INDEX IF NOT EXISTS idx_hotel_booking_options_hotel_id ON hotel_booking_options(hotel_id);
CREATE INDEX IF NOT EXISTS idx_hotel_booking_options_serpapi_link ON hotel_booking_options(serpapi_link);
CREATE INDEX IF NOT EXISTS idx_hotel_booking_options_fetched_at ON hotel_booking_options(fetched_at);
