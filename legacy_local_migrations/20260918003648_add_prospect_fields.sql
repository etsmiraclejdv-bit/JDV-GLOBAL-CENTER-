-- Add temperature and prospect fields to clients table
ALTER TABLE public.clients
ADD COLUMN IF NOT EXISTS temperature TEXT DEFAULT 'cold' CHECK (temperature IN ('hot', 'warm', 'cold')),
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS city TEXT,
ADD COLUMN IF NOT EXISTS quartier TEXT,
ADD COLUMN IF NOT EXISTS lieu_rencontre TEXT,
ADD COLUMN IF NOT EXISTS notes TEXT,
ADD COLUMN IF NOT EXISTS desired_product TEXT,
ADD COLUMN IF NOT EXISTS desired_quantity INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS proposed_price BIGINT DEFAULT 0,
ADD COLUMN IF NOT EXISTS interest_level TEXT DEFAULT 'medium' CHECK (interest_level IN ('low', 'medium', 'high')),
ADD COLUMN IF NOT EXISTS next_contact_date DATE,
ADD COLUMN IF NOT EXISTS appointment_date DATE,
ADD COLUMN IF NOT EXISTS appointment_time TIME,
ADD COLUMN IF NOT EXISTS appointment_location TEXT,
ADD COLUMN IF NOT EXISTS is_prospect BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS converted_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS phone2 TEXT;

-- Add index for temperature filter
CREATE INDEX IF NOT EXISTS idx_clients_temperature ON public.clients(temperature);
CREATE INDEX IF NOT EXISTS idx_clients_is_prospect ON public.clients(is_prospect);
CREATE INDEX IF NOT EXISTS idx_clients_next_contact ON public.clients(next_contact_date);
CREATE INDEX IF NOT EXISTS idx_clients_assigned_to ON public.clients(assigned_to);
