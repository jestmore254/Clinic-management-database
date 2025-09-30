CREATE DATABASE IF NOT EXISTS clinic_db;
USE clinic_db;

-- Drop existing tables (safe re-run)
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS Payments;
DROP TABLE IF EXISTS Billing;
DROP TABLE IF EXISTS PrescriptionItems;
DROP TABLE IF EXISTS Prescriptions;
DROP TABLE IF EXISTS Medications;
DROP TABLE IF EXISTS MedicalRecords;
DROP TABLE IF EXISTS Appointments;
DROP TABLE IF EXISTS Rooms;
DROP TABLE IF EXISTS DoctorSpecialties;
DROP TABLE IF EXISTS Doctors;
DROP TABLE IF EXISTS Specialties;
DROP TABLE IF EXISTS Patients;
SET FOREIGN_KEY_CHECKS = 1;

------------------------------------------------------------
-- Core lookup tables
------------------------------------------------------------

-- Specialties (e.g., Pediatrics, General, Cardiology)
CREATE TABLE Specialties (
    SpecialtyID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL UNIQUE,
    Description VARCHAR(255)
);

-- Medications catalog
CREATE TABLE Medications (
    MedicationID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(150) NOT NULL UNIQUE,
    Manufacturer VARCHAR(150),
    Formulation VARCHAR(100) -- e.g., tablet, syrup
);

------------------------------------------------------------
-- People and roles
------------------------------------------------------------

-- Doctors table
CREATE TABLE Doctors (
    DoctorID INT AUTO_INCREMENT PRIMARY KEY,
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    Email VARCHAR(150) NOT NULL UNIQUE,
    Phone VARCHAR(30),
    LicenseNo VARCHAR(50) NOT NULL UNIQUE,
    HiredDate DATE,
    Active TINYINT(1) DEFAULT 1
);

-- Patients table
CREATE TABLE Patients (
    PatientID INT AUTO_INCREMENT PRIMARY KEY,
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    DateOfBirth DATE,
    Gender ENUM('Male','Female','Other') DEFAULT 'Other',
    Email VARCHAR(150),
    Phone VARCHAR(30),
    Address VARCHAR(255),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Many-to-many: DoctorSpecialties (a doctor can have multiple specialties)
CREATE TABLE DoctorSpecialties (
    DoctorID INT NOT NULL,
    SpecialtyID INT NOT NULL,
    PRIMARY KEY (DoctorID, SpecialtyID),
    FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (SpecialtyID) REFERENCES Specialties(SpecialtyID) ON DELETE CASCADE ON UPDATE CASCADE
);

------------------------------------------------------------
-- Facility and scheduling
------------------------------------------------------------

-- Rooms (exam rooms or consultation rooms)
CREATE TABLE Rooms (
    RoomID INT AUTO_INCREMENT PRIMARY KEY,
    RoomNumber VARCHAR(20) NOT NULL UNIQUE,
    Floor VARCHAR(20),
    Notes VARCHAR(255)
);

-- Appointments
-- One appointment is for one patient and one doctor (One-to-Many in tables)
CREATE TABLE Appointments (
    AppointmentID INT AUTO_INCREMENT PRIMARY KEY,
    PatientID INT NOT NULL,
    DoctorID INT NOT NULL,
    RoomID INT, -- optional
    ScheduledStart DATETIME NOT NULL,
    ScheduledEnd DATETIME NOT NULL,
    Status ENUM('Scheduled','CheckedIn','Completed','Cancelled','NoShow') DEFAULT 'Scheduled',
    Reason VARCHAR(255),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_app_patient FOREIGN KEY (PatientID) REFERENCES Patients(PatientID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_app_doctor FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_app_room FOREIGN KEY (RoomID) REFERENCES Rooms(RoomID) ON DELETE SET NULL ON UPDATE CASCADE,
    -- Prevent scheduling an appointment with non-sensical times
    CHECK (ScheduledEnd > ScheduledStart)
);

-- Index for quick lookups by doctor and date
CREATE INDEX idx_appointments_doctor_start ON Appointments(DoctorID, ScheduledStart);

------------------------------------------------------------
-- Medical records and prescriptions
------------------------------------------------------------

-- MedicalRecords: one-to-many (a patient can have many records)
CREATE TABLE MedicalRecords (
    RecordID INT AUTO_INCREMENT PRIMARY KEY,
    PatientID INT NOT NULL,
    AppointmentID INT, -- optional link to appointment
    RecordDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    Notes TEXT,
    Diagnosis VARCHAR(255),
    FOREIGN KEY (PatientID) REFERENCES Patients(PatientID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (AppointmentID) REFERENCES Appointments(AppointmentID) ON DELETE SET NULL ON UPDATE CASCADE
);

-- Prescriptions: each prescription issued by a doctor for a patient (can link to appointment)
CREATE TABLE Prescriptions (
    PrescriptionID INT AUTO_INCREMENT PRIMARY KEY,
    PatientID INT NOT NULL,
    DoctorID INT NOT NULL,
    AppointmentID INT,
    IssuedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    Notes VARCHAR(500),
    FOREIGN KEY (PatientID) REFERENCES Patients(PatientID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (AppointmentID) REFERENCES Appointments(AppointmentID) ON DELETE SET NULL ON UPDATE CASCADE
);

-- PrescriptionItems: many-to-many between Prescriptions and Medications with extra attributes
CREATE TABLE PrescriptionItems (
    PrescriptionID INT NOT NULL,
    MedicationID INT NOT NULL,
    Dosage VARCHAR(100) NOT NULL, -- e.g., "500mg twice daily"
    Duration VARCHAR(50), -- e.g., "7 days"
    Quantity INT DEFAULT 1,
    PRIMARY KEY (PrescriptionID, MedicationID),
    FOREIGN KEY (PrescriptionID) REFERENCES Prescriptions(PrescriptionID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (MedicationID) REFERENCES Medications(MedicationID) ON DELETE RESTRICT ON UPDATE CASCADE
);

------------------------------------------------------------
-- Billing and payments
------------------------------------------------------------

-- Billing: one bill per appointment or per service
CREATE TABLE Billing (
    BillID INT AUTO_INCREMENT PRIMARY KEY,
    AppointmentID INT,
    PatientID INT NOT NULL,
    IssuedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    TotalAmount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    PaidAmount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    Status ENUM('Unpaid','PartiallyPaid','Paid','Cancelled') DEFAULT 'Unpaid',
    FOREIGN KEY (AppointmentID) REFERENCES Appointments(AppointmentID) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (PatientID) REFERENCES Patients(PatientID) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Payments linked to a bill
CREATE TABLE Payments (
    PaymentID INT AUTO_INCREMENT PRIMARY KEY,
    BillID INT NOT NULL,
    PaidAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    Amount DECIMAL(10,2) NOT NULL,
    Method ENUM('Cash','Card','MobileMoney','Insurance') DEFAULT 'Cash',
    TransactionReference VARCHAR(150),
    FOREIGN KEY (BillID) REFERENCES Billing(BillID) ON DELETE CASCADE ON UPDATE CASCADE
);

------------------------------------------------------------
-- Example seed data (optional) - comment out if not needed
------------------------------------------------------------

-- Insert some specialties
INSERT INTO Specialties (Name, Description) VALUES
('General Practice','General health and primary care'),
('Pediatrics','Child health'),
('Cardiology','Heart specialist');

-- Insert doctors
INSERT INTO Doctors (FirstName, LastName, Email, Phone, LicenseNo, HiredDate) VALUES
('Alice','Mwangi','alice.mwangi@clinic.example','+254700000001','LIC-1001','2019-03-10'),
('James','Otieno','james.otieno@clinic.example','+254700000002','LIC-1002','2021-06-15');

-- Assign specialties
INSERT INTO DoctorSpecialties (DoctorID, SpecialtyID) VALUES
(1, 1),
(1, 2),
(2, 1),
(2, 3);

-- Insert patients
INSERT INTO Patients (FirstName, LastName, DateOfBirth, Gender, Email, Phone, Address) VALUES
('John','Doe','1984-07-20','Male','john.doe@example.com','+254711000111','Nairobi'),
('Jane','Kamau','1990-11-02','Female','jane.kamau@example.com','+254711000222','Nakuru');

-- Insert rooms
INSERT INTO Rooms (RoomNumber, Floor, Notes) VALUES
('R101','1','General consultation'),
('R102','1','Pediatrics');

-- Insert meds
INSERT INTO Medications (Name, Manufacturer, Formulation) VALUES
('Amoxicillin','PharmaCo','Capsule'),
('Paracetamol','MediLab','Tablet');

-- Sample appointment and follow-up records
INSERT INTO Appointments (PatientID, DoctorID, RoomID, ScheduledStart, ScheduledEnd, Status, Reason)
VALUES
(1, 1, 1, '2025-10-05 09:00:00', '2025-10-05 09:20:00', 'Scheduled', 'Fever and cough'),
(2, 2, 2, '2025-10-05 10:00:00', '2025-10-05 10:30:00', 'Scheduled', 'Routine check');

-- Sample medical record and prescription
INSERT INTO MedicalRecords (PatientID, AppointmentID, Notes, Diagnosis)
VALUES (1, 1, 'High temperature. Throat redness.', 'Upper respiratory infection');

INSERT INTO Prescriptions (PatientID, DoctorID, AppointmentID, Notes)
VALUES (1, 1, 1, 'Take as directed');

INSERT INTO PrescriptionItems (PrescriptionID, MedicationID, Dosage, Duration, Quantity)
VALUES (1, 1, '500mg three times a day', '5 days', 15);

-- Sample billing and payment
INSERT INTO Billing (AppointmentID, PatientID, TotalAmount, PaidAmount, Status)
VALUES (1, 1, 1500.00, 0.00, 'Unpaid');

INSERT INTO Payments (BillID, Amount, Method, TransactionReference)
VALUES (1, 1500.00, 'MobileMoney', 'TXN-123456');

-- Update billing status after payment
UPDATE Billing SET PaidAmount = PaidAmount + 1500.00, Status = 'Paid' WHERE BillID = 1;



