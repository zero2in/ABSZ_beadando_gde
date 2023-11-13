CREATE TABLE vehicles(
    vehicleID SERIAL PRIMARY KEY, -- jarmu azonosito
    vin VARCHAR(255) CHECK (vin ~ '^[A-Z]{3,4}-[0-9]{3}$'), -- rendszam
    vehicle_typeID_vehicle INTEGER REFERENCES vehicle_type(vehicle_typeID), -- auto tipus azonosito
    rentable BOOLEAN NOT NULL, -- berelheto
    man_year INTEGER NOT NULL, -- gyartasi ev
    condition_desc TEXT, -- allapot leiras
);

CREATE TABLE vehicle_type(
    vehicle_typeID SERIAL PRIMARY KEY,
    vehicle_type_description TEXT
);

CREATE TABLE rental(
    rentalID SERIAL PRIMARY KEY,
    vehicleID_rental INTEGER NOT NULL REFERENCES vehicles(vehicleID),
    customerID_rental INTEGER NOT NULL REFERENCES customer(customerID),
    pickup_date DATE,
    dropoff_date DATE
);

CREATE INDEX idx_vechicle_ID_rental on rental(vehicleID_rental);
CREATE INDEX idx_customer_ID_rental on rental(customerD_rental);

CREATE TABLE customer(
    customerID SERIAL PRIMARY KEY,
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50),
    county_ID INTEGER NOT NULL REFERENCES county(county_ID), -- igy kell kulso kulcsot csinalni
    post_code VARCHAR(50) NOT NULL,
    city VARCHAR(50) NOT NULL,
    _address VARCHAR(50) NOT NULL
    -- rakerdezni hogy igy jo-e
);
CREATE INDEX idx_county_id_customer on customer(county_ID);

CREATE TABLE county(
    county_ID SERIAL PRIMARY KEY,
    county_name VARCHAR(50)
); -- megyekkel feltolteni

CREATE TABLE bill_header(
    bill_ID SERIAL PRIMARY KEY,
    bill_date DATE,
);

CREATE TABLE bill_body(
    bill_ID INTEGER,
    rental_ID INTEGER
);

--LEKERDEZESEK:

-- elerheto jarmuvek
SELECT * FROM vehicles WHERE rentable=1;
-- nem elerheto jarmuvek
SELECT * FROM vehicles WHERE rentable=0;
--elozo ketto egyben
SELECT * FROM vehicles ORDER BY rentable;
-- vasarlo kolcsonzesi elozmenyei
SELECT customerID_rental, vehicleID_rental FROM rental ORDER BY customerID_rental;
--TRIGGER

-- Első lépés: Hozd létre a triggert
CREATE OR REPLACE FUNCTION update_rentable_status()
RETURNS TRIGGER AS $$
BEGIN
  -- Ellenőrizzük, hogy az új kölcsönzés alapján módosítani kell-e a rentable mezőt
  IF EXISTS (
    SELECT 1
    FROM rental r
    JOIN vehicles v ON r.vehicleID_rental = v.vehicleID
    WHERE r.rentalID = NEW.rentalID
  ) THEN
    -- Ha van ilyen rekord, akkor állítsd be a rentable mezőt False-ra
    UPDATE vehicles
    SET rentable = FALSE
    WHERE vehicleID = NEW.vehicleID_rental;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Második lépés: Hozz létre a triggert az AFTER INSERT eseményhez
CREATE TRIGGER update_rentable_trigger
AFTER INSERT ON rental
FOR EACH ROW
EXECUTE FUNCTION update_rentable_status();
