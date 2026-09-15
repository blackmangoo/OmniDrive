-- ==============================================================================
-- 🚗 OmniDrive AI — Complete PostgreSQL Database Schema
-- Target Engine: Supabase PostgreSQL 17 with pgvector extension
-- Covers: 13 Tables, Indexes, Custom RPCs, Triggers, and Row-Level Security (RLS)
-- ==============================================================================

-- 1. Enable Required Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "vector";

-- ==============================================================================
-- 2. ENUMS & DOMAINS
-- ==============================================================================
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('customer', 'vendor', 'rider', 'admin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE order_status AS ENUM ('pending', 'confirmed', 'ready', 'dispatched', 'delivered', 'cancelled');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ==============================================================================
-- 3. CORE IDENTITY & AUTH TABLES
-- ==============================================================================

-- 3.1 User Profiles (Linked to auth.users)
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL DEFAULT 'customer',
    full_name TEXT,
    phone TEXT,
    avatar_url TEXT,
    address TEXT,
    fcm_token TEXT,
    is_approved BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.2 Vendor Profiles
CREATE TABLE IF NOT EXISTS public.vendor_profiles (
    id UUID PRIMARY KEY REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    shop_name TEXT NOT NULL,
    shop_description TEXT,
    shop_logo_url TEXT,
    shop_banner_url TEXT,
    location TEXT,
    phone TEXT,
    rating NUMERIC(3, 2) DEFAULT 5.00,
    total_orders INT DEFAULT 0,
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    fcm_token TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.3 User Registered Vehicles
CREATE TABLE IF NOT EXISTS public.user_cars (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    make TEXT NOT NULL,
    model TEXT NOT NULL,
    year INT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 4. AI VISION & KNOWLEDGE BASE TABLES
-- ==============================================================================

-- 4.1 Car Parts Metadata (50 YOLO Classes)
CREATE TABLE IF NOT EXISTS public.car_parts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_name TEXT UNIQUE NOT NULL,
    description TEXT,
    average_price NUMERIC(10, 2),
    compatibility_notes TEXT,
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4.2 Scan History (YOLO11 Vision Logs)
CREATE TABLE IF NOT EXISTS public.scan_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    image_url TEXT NOT NULL,
    predicted_class TEXT NOT NULL,
    confidence NUMERIC(5, 2) NOT NULL,
    inference_time_ms NUMERIC(8, 2),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4.3 Part Technical Documentation (pgvector RAG Store)
CREATE TABLE IF NOT EXISTS public.part_docs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content TEXT NOT NULL,
    embedding vector(768),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create HNSW index for high-performance approximate nearest neighbor retrieval
CREATE INDEX IF NOT EXISTS part_docs_embedding_idx
ON public.part_docs
USING hnsw (embedding vector_cosine_ops);

-- ==============================================================================
-- 5. MARKETPLACE TABLES
-- ==============================================================================

-- 5.1 Categories
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    icon_name TEXT,
    color TEXT,
    display_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5.2 Products
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES public.vendor_profiles(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    compare_price NUMERIC(10, 2),
    stock_quantity INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    unit TEXT DEFAULT 'piece',
    images TEXT[] DEFAULT ARRAY[]::TEXT[],
    sku TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5.3 Shopping Cart Items
CREATE TABLE IF NOT EXISTS public.cart_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    quantity INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_user_product UNIQUE (user_id, product_id)
);

-- 5.4 Orders
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE RESTRICT,
    vendor_id UUID NOT NULL REFERENCES public.vendor_profiles(id) ON DELETE RESTRICT,
    rider_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    total_amount NUMERIC(10, 2) NOT NULL CHECK (total_amount >= 0),
    delivery_address TEXT NOT NULL,
    delivery_fee NUMERIC(10, 2) DEFAULT 0.00,
    customer_notes TEXT,
    payment_method VARCHAR(30) DEFAULT 'COD',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5.5 Order Line Items
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10, 2) NOT NULL,
    product_name TEXT NOT NULL,
    product_image TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5.6 In-App Notifications
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,
    data JSONB DEFAULT '{}'::jsonb,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 6. TELEMETRY & PERFORMANCE RUNS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.performance_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    car_id UUID REFERENCES public.user_cars(id) ON DELETE SET NULL,
    test_type VARCHAR(50) NOT NULL,
    time_seconds NUMERIC(8, 3),
    top_speed_kmh NUMERIC(6, 2),
    sensor_mode VARCHAR(20) DEFAULT 'gps_imu',
    speed_time_json JSONB DEFAULT '[]'::jsonb,
    conditions TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 7. DATABASE FUNCTIONS & RPCS
-- ==============================================================================

-- 7.1 Atomic Stock Decrement RPC
CREATE OR REPLACE FUNCTION public.decrement_stock(
    p_product_id UUID,
    p_quantity INT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_stock INT;
BEGIN
    SELECT stock_quantity INTO v_current_stock
    FROM public.products
    WHERE id = p_product_id
    FOR UPDATE;

    IF v_current_stock IS NULL OR v_current_stock < p_quantity THEN
        RETURN FALSE;
    END IF;

    UPDATE public.products
    SET stock_quantity = stock_quantity - p_quantity,
        updated_at = NOW()
    WHERE id = p_product_id;

    RETURN TRUE;
END;
$$;

-- 7.2 RAG Cosine Similarity Document Matcher RPC
CREATE OR REPLACE FUNCTION public.match_documents (
    query_embedding vector(768),
    match_threshold FLOAT,
    match_count INT
)
RETURNS TABLE (
    id UUID,
    content TEXT,
    similarity FLOAT
)
LANGUAGE sql STABLE
AS $$
    SELECT
        part_docs.id,
        part_docs.content,
        1 - (part_docs.embedding <=> query_embedding) AS similarity
    FROM public.part_docs
    WHERE 1 - (part_docs.embedding <=> query_embedding) > match_threshold
    ORDER BY part_docs.embedding <=> query_embedding
    LIMIT match_count;
$$;

-- 7.3 Handle New Auth User (Auto-trigger profile creation)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_role TEXT;
    v_full_name TEXT;
    v_phone TEXT;
    v_approved BOOLEAN;
BEGIN
    v_role := COALESCE(NEW.raw_user_meta_data->>'role', 'customer');
    v_full_name := COALESCE(NEW.raw_user_meta_data->>'full_name', 'User');
    v_phone := NEW.raw_user_meta_data->>'phone';

    -- Customers auto-approved; Vendors & Riders require Admin approval
    IF v_role = 'vendor' OR v_role = 'rider' THEN
        v_approved := FALSE;
    ELSE
        v_approved := TRUE;
    END IF;

    INSERT INTO public.user_profiles (id, role, full_name, phone, is_approved)
    VALUES (NEW.id, v_role, v_full_name, v_phone, v_approved)
    ON CONFLICT (id) DO UPDATE SET
        role = EXCLUDED.role,
        full_name = EXCLUDED.full_name;

    -- If vendor, prepare basic vendor profile record
    IF v_role = 'vendor' THEN
        INSERT INTO public.vendor_profiles (id, shop_name, location, phone)
        VALUES (
            NEW.id,
            COALESCE(NEW.raw_user_meta_data->>'shop_name', 'Shop ' || SUBSTRING(NEW.id::text FROM 1 FOR 6)),
            NEW.raw_user_meta_data->>'location',
            v_phone
        )
        ON CONFLICT (id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$;

-- Trigger firing on new user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 7.4 Admin Approval Helpers
CREATE OR REPLACE FUNCTION public.approve_user(p_user_id UUID, p_role TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.user_profiles
    SET is_approved = TRUE, updated_at = NOW()
    WHERE id = p_user_id;

    IF p_role = 'vendor' THEN
        UPDATE public.vendor_profiles
        SET is_verified = TRUE, is_active = TRUE, updated_at = NOW()
        WHERE id = p_user_id;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.reject_user(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM public.user_profiles WHERE id = p_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_pending_approvals()
RETURNS TABLE (
    id UUID,
    full_name TEXT,
    email TEXT,
    role VARCHAR,
    phone TEXT,
    created_at TIMESTAMPTZ,
    shop_name TEXT,
    location TEXT
)
LANGUAGE sql STABLE SECURITY DEFINER
AS $$
    SELECT
        u.id,
        u.full_name,
        au.email,
        u.role,
        u.phone,
        u.created_at,
        v.shop_name,
        v.location
    FROM public.user_profiles u
    JOIN auth.users au ON au.id = u.id
    LEFT JOIN public.vendor_profiles v ON v.id = u.id
    WHERE u.is_approved = FALSE
    ORDER BY u.created_at DESC;
$$;

-- ==============================================================================
-- 8. ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

-- Enable RLS across all tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendor_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_cars ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.car_parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scan_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.part_docs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance_runs ENABLE ROW LEVEL SECURITY;

-- 8.1 Public Read for Catalogs
CREATE POLICY "Public can view categories" ON public.categories FOR SELECT USING (true);
CREATE POLICY "Public can view active products" ON public.products FOR SELECT USING (is_active = true OR auth.uid() = vendor_id);
CREATE POLICY "Public can view car parts" ON public.car_parts FOR SELECT USING (true);
CREATE POLICY "Public can view part docs" ON public.part_docs FOR SELECT USING (true);

-- 8.2 User Isolation Policies
CREATE POLICY "Users view own profile" ON public.user_profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users insert own profile" ON public.user_profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users update own profile" ON public.user_profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users delete own profile" ON public.user_profiles FOR DELETE USING (auth.uid() = id);

CREATE POLICY "Users view own cart" ON public.cart_items FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users manage own cart" ON public.cart_items FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users view own scans" ON public.scan_history FOR SELECT USING (auth.uid() = user_id OR user_id IS NULL);
CREATE POLICY "Users insert scans" ON public.scan_history FOR INSERT WITH CHECK (true);

CREATE POLICY "Users view own performance runs" ON public.performance_runs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own performance runs" ON public.performance_runs FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users view own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users update own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

-- 8.3 Vendor Product Management
CREATE POLICY "Vendors manage own products" ON public.products FOR ALL USING (auth.uid() = vendor_id);
CREATE POLICY "Public view vendor profiles" ON public.vendor_profiles FOR SELECT USING (true);
CREATE POLICY "Vendors update own vendor profile" ON public.vendor_profiles FOR UPDATE USING (auth.uid() = id);

-- 8.4 Order Access
CREATE POLICY "Participants view orders" ON public.orders FOR SELECT
USING (auth.uid() = customer_id OR auth.uid() = vendor_id OR auth.uid() = rider_id OR (status = 'ready' AND rider_id IS NULL));

CREATE POLICY "Customers place orders" ON public.orders FOR INSERT
WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Participants update orders" ON public.orders FOR UPDATE
USING (auth.uid() = customer_id OR auth.uid() = vendor_id OR auth.uid() = rider_id OR (status = 'ready' AND rider_id IS NULL));

CREATE POLICY "Participants view order items" ON public.order_items FOR SELECT
USING (EXISTS (SELECT 1 FROM public.orders o WHERE o.id = order_items.order_id AND (o.customer_id = auth.uid() OR o.vendor_id = auth.uid() OR o.rider_id = auth.uid())));
