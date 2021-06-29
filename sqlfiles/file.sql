\ir filed.sql

-------------------------------------------------------------------------------
-- UUID Generation Extension
-------------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-------------------------------------------------------------------------------
-- Get All UUIDs From a Table
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION uuids_from_table(tblname text) 
RETURNS SETOF uuid
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY EXECUTE format('SELECT id FROM %I', tblname);
END; $$;


-------------------------------------------------------------------------------
-- Generate a Unique UUID for any Table
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION unique_uuid(tblname text)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    uuid    uuid := (SELECT uuid_generate_v4());
BEGIN
    WHILE uuid IN (SELECT uuids_from_table(tblname)) LOOP
        uuid := (SELECT uuid_generate_v4());
    END LOOP;
    
    RETURN (SELECT uuid);
END; $$;


-------------------------------------------------------------------------------
-- Table of Users
-------------------------------------------------------------------------------
CREATE TABLE users (
    id uuid DEFAULT unique_uuid('users'),
    username text NOT NULL,
    f_name text NULL,
    l_name text NULL,
    CONSTRAINT users_id_pk PRIMARY KEY(id),
    CONSTRAINT username_unique UNIQUE(username)
);


-------------------------------------------------------------------------------
-- Table of Files
-------------------------------------------------------------------------------
CREATE TABLE files (
    id uuid DEFAULT unique_uuid('files'),
    user_id uuid NOT NULL, 
    filename text NOT NULL,
    title text NOT NULL,
    description text,
    date_added date DEFAULT now(),
    CONSTRAINT files_id_pk PRIMARY KEY(id),
    CONSTRAINT user_id_fk FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT date_valid CHECK(date_added <= now())
);


-------------------------------------------------------------------------------
-- Table of Shared Files
-------------------------------------------------------------------------------
CREATE TABLE shared_files (
    id uuid DEFAULT unique_uuid('shared_files'),
    file_id uuid NOT NULL,
    user_id uuid NOT NULL,
    -- shared_user_id uuid NOT NULL,
    CONSTRAINT shared_files_id_pk PRIMARY KEY(id),
    CONSTRAINT file_id_fk FOREIGN KEY(file_id) REFERENCES files(id) ON DELETE CASCADE,
    CONSTRAINT user_id_fk FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
    -- CONSTRAINT shared_user_id_fk FOREIGN KEY(shared_user_id) REFERENCES users(id),
    -- CONSTRAINT onetime_share UNIQUE(file_id, shared_user_id),
    CONSTRAINT onetime_share UNIQUE(file_id, user_id)
    -- CONSTRAINT no_share_self CHECK(user_id != shared_user_id)
);


-------------------------------------------------------------------------------
-- View of Accessible files
-------------------------------------------------------------------------------
CREATE OR REPLACE VIEW file_access AS
    SELECT u.id AS user_id, u.username AS username, u.id AS owner_id, u.username AS owner_username, f.id AS file_id, f.filename
        FROM users AS u 
        JOIN files AS f ON u.id = f.user_id
        UNION
    SELECT shf.user_id AS user_id, shu.username AS username, f2.user_id AS owner_id, u2.username AS owner_username, f2.id AS file_id, f2.filename
        FROM files AS f2
        JOIN shared_files AS shf ON f2.id = shf.file_id
        JOIN users as u2 ON u2.id = f2.user_id
        JOIN users as shu ON shu.id = shf.user_id
    ORDER BY user_id, owner_id, file_id;


-------------------------------------------------------------------------------
-- Query Accessible Files for a User 
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION user_file_access (userid uuid)
RETURNS SETOF file_access
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
        SELECT * FROM file_access WHERE user_id = userid;
END; $$;

-------------------------------------------------------------------------------
-- Dummy Data
-------------------------------------------------------------------------------
-- INSERT INTO users(username, f_name, l_name)
-- VALUES
--     ('admin', 'admin', 'admin'),
--     ('bob', 'bob', 'bob') 
--     RETURNING id;
-- SELECT * FROM users;

-- INSERT INTO files(user_id, filename, description, date_added)
-- VALUES
--     ((SELECT id FROM users WHERE username = 'admin'), 'AdminFile.zip', NULL, (SELECT now())),
--     ((SELECT id FROM users WHERE username = 'bob'), 'BobFile.zip', NULL, (SELECT now())),
--     ((SELECT id FROM users WHERE username = 'bob'), 'BobFile2.zip', 'Reathon', (SELECT now())) 
--     RETURNING id;
-- SELECT * FROM files;

-- INSERT INTO shared_files(file_id, user_id)
-- VALUES
--     ((SELECT f.id FROM files AS f JOIN users AS u ON u.id = f.user_id WHERE u.username = 'admin'),
--         (SELECT u.id FROM users AS u WHERE u.username = 'bob')),
--     ((SELECT f.id FROM files AS f JOIN users AS u ON u.id = f.user_id WHERE u.username = 'bob' AND f.filename LIKE '%2.zip'),
--         (SELECT u.id FROM users AS u WHERE u.username = 'admin')) 
--     RETURNING id;
-- SELECT * FROM shared_files;


-------------------------------------------------------------------------------
-- Bad Data
-------------------------------------------------------------------------------
-- INSERT INTO shared_files(file_id, user_id)
-- VALUES
--     ((SELECT f.id FROM files AS f JOIN users AS u ON u.id = f.user_id WHERE u.username = 'admin'),
--         (SELECT u.id FROM users AS u WHERE u.username = 'bob')) 
--     RETURNING id;


-------------------------------------------------------------------------------
-- View Data
-------------------------------------------------------------------------------
SELECT * FROM file_access;
SELECT * FROM user_file_access((SELECT id FROM users WHERE username = 'admin'));