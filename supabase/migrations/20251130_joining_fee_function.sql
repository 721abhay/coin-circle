-- Helper function to calculate joining fee based on contribution amount
-- Max joining fee is ₹100
CREATE OR REPLACE FUNCTION calculate_joining_fee(contribution_amount NUMERIC)
RETURNS NUMERIC AS $$
BEGIN
  -- Joining fee structure (capped at ₹100):
  -- Under ₹1000 = ₹50
  -- ₹1000-₹2999 = ₹60
  -- ₹3000-₹4999 = ₹70
  -- ₹5000-₹9999 = ₹80
  -- ₹10000+ = ₹100 (capped)
  
  IF contribution_amount < 1000 THEN
    RETURN 50;
  ELSIF contribution_amount < 3000 THEN
    RETURN 60;
  ELSIF contribution_amount < 5000 THEN
    RETURN 70;
  ELSIF contribution_amount < 10000 THEN
    RETURN 80;
  ELSE
    RETURN 100; -- Capped at ₹100
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION calculate_joining_fee IS 'Calculates joining fee based on contribution amount. Maximum fee is ₹100.';
