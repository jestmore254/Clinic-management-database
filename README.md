📘 Clinic Booking System — README
📌 Overview

The Clinic Booking System Database is a relational schema built in MySQL.
It manages patients, doctors, appointments, prescriptions, billing, and payments.
The design follows good database practices with normalization, primary keys, foreign keys, and proper constraints to ensure data integrity.

🎯 Objectives

Store clinic information in a structured way.

Handle appointments between doctors and patients.

Manage medical records and prescriptions.

Track billing and payments.

Provide relationships between entities (One-to-One, One-to-Many, Many-to-Many).

🏗️ Database Structure
1. Specialties

Stores different doctor specialties (e.g., Pediatrics, Cardiology).

Primary Key: SpecialtyID

Important Constraints: Name is UNIQUE.

2. Medications

Catalog of medicines prescribed to patients.

Primary Key: MedicationID

Important Constraints: Name is UNIQUE.

3. Doctors

Stores details of clinic doctors.

Primary Key: DoctorID

Important Constraints: Email and LicenseNo are UNIQUE.

4. Patients

Stores personal and contact information of patients.

Primary Key: PatientID

5. DoctorSpecialties (Many-to-Many)

Connects doctors to their specialties.

Primary Key: (DoctorID, SpecialtyID)

Foreign Keys: References Doctors and Specialties.

6. Rooms

Clinic rooms used for appointments.

Primary Key: RoomID

Important Constraints: RoomNumber is UNIQUE.

7. Appointments

Manages scheduling of patients with doctors.

Primary Key: AppointmentID

Foreign Keys: PatientID, DoctorID, RoomID

Constraints: ScheduledEnd > ScheduledStart

8. MedicalRecords

Stores diagnosis and notes for patients.

Primary Key: RecordID

Foreign Keys: PatientID, optional AppointmentID

9. Prescriptions

Holds prescription details for patients issued by doctors.

Primary Key: PrescriptionID

Foreign Keys: PatientID, DoctorID, optional AppointmentID

10. PrescriptionItems (Many-to-Many with details)

Connects prescriptions to medications with dosage and duration.

Primary Key: (PrescriptionID, MedicationID)

Foreign Keys: References Prescriptions and Medications.

11. Billing

Stores billing information for services and appointments.

Primary Key: BillID

Foreign Keys: PatientID, optional AppointmentID

12. Payments

Tracks payments made towards bills.

Primary Key: PaymentID

Foreign Key: BillID

🔗 Relationships

One-to-Many:

One Doctor → Many Appointments

One Patient → Many Appointments

One Bill → Many Payments

Many-to-Many:

Doctors ↔ Specialties via DoctorSpecialties

Prescriptions ↔ Medications via PrescriptionItems

Optional Relationships:

Appointments may link to Rooms.

MedicalRecords and Prescriptions may link to Appointments.
