-- Create Support Tickets Table
CREATE TABLE IF NOT EXISTS support_tickets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    category TEXT NOT NULL,
    subject TEXT NOT NULL,
    description TEXT NOT NULL,
    priority TEXT NOT NULL DEFAULT 'Medium',
    status TEXT NOT NULL DEFAULT 'open', -- open, in_progress, resolved, closed
    attachments TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;

-- RLS Policies for support_tickets
CREATE POLICY "Users can create their own tickets"
    ON support_tickets FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own tickets"
    ON support_tickets FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all tickets"
    ON support_tickets FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
        )
    );

CREATE POLICY "Admins can update tickets"
    ON support_tickets FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
        )
    );

-- Create FAQs Table
CREATE TABLE IF NOT EXISTS faqs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    category TEXT,
    is_published BOOLEAN DEFAULT TRUE,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE faqs ENABLE ROW LEVEL SECURITY;

-- RLS Policies for faqs
CREATE POLICY "Everyone can view published faqs"
    ON faqs FOR SELECT
    USING (is_published = TRUE);

CREATE POLICY "Admins can manage faqs"
    ON faqs FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
        )
    );

-- Create Tutorials Table
CREATE TABLE IF NOT EXISTS tutorials (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    video_url TEXT,
    thumbnail_url TEXT,
    is_published BOOLEAN DEFAULT TRUE,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE tutorials ENABLE ROW LEVEL SECURITY;

-- RLS Policies for tutorials
CREATE POLICY "Everyone can view published tutorials"
    ON tutorials FOR SELECT
    USING (is_published = TRUE);

CREATE POLICY "Admins can manage tutorials"
    ON tutorials FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
        )
    );

-- Insert some default FAQs
INSERT INTO faqs (question, answer, category, display_order) VALUES
('How do I join a pool?', 'To join a pool, navigate to the "Pools" tab, browse available pools, and click "Join". You will need to agree to the terms and contribute the first installment.', 'Pool Management', 1),
('How are winners selected?', 'Winners are selected randomly using a secure, transparent algorithm at the end of each contribution cycle.', 'Winner Selection', 2),
('Is my money safe?', 'Yes, all funds are held in secure escrow accounts and released only to the verified winner of each cycle.', 'Security', 3),
('Can I withdraw my funds early?', 'Early withdrawal is generally not permitted to ensure the integrity of the pool. However, in emergencies, you can request a special withdrawal which may incur a penalty.', 'Payments', 4);
