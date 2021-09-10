\ir destroy/filed.sql

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
CREATE TABLE app_user (
    id uuid DEFAULT unique_uuid('app_user'),
    username text NOT NULL,
    f_name text NULL,
    l_name text NULL,
    CONSTRAINT app_user_id_pk PRIMARY KEY(id),
    CONSTRAINT username_unique UNIQUE(username)
);


-------------------------------------------------------------------------------
-- Table of Files
-------------------------------------------------------------------------------
CREATE TABLE file (
    id uuid DEFAULT unique_uuid('file'),
    -- user_id uuid NOT NULL, 
    filename text NOT NULL,
    title text NOT NULL,
    description text,
    -- anonymous_access boolean NOT NULL DEFAULT FALSE,
    date_added date NOT NULL DEFAULT now(),
    CONSTRAINT files_id_pk PRIMARY KEY(id),
    -- CONSTRAINT user_id_fk FOREIGN KEY(user_id) REFERENCES app_user(id) ON DELETE CASCADE,
    CONSTRAINT date_valid CHECK(date_added <= now())
);

-------------------------------------------------------------------------------
-- Table of Ways to Share File
-------------------------------------------------------------------------------
-- CREATE TABLE share_type (
--     id bigint NOT NULL DEFAULT nextval('share_type_s'),
--     title text NOT NULL,
--     CONSTRAINT share_type_pk PRIMARY KEY(id),
--     CONSTRAINT share_type_unique_title UNIQUE(title)
-- );
-- CREATE SEQUENCE share_type_s START WITH 1000 INCREMENT BY 1 OWNED BY share_type.id;

-- INSERT INTO share_type (title)
-- VALUES
--     ('ANONYMOUS'),
--     ('LINK')
--     RETURNING *;

-------------------------------------------------------------------------------
-- Table of Ways a File is Shared
-------------------------------------------------------------------------------
-- CREATE TABLE share_by (
--     file_id uuid NOT NULL,
--     share_type_id uuid  NOT NULL,
--     CONSTRAINT share_by_pk PRIMARY KEY(file_id, share_type_id),
--     CONSTRAINT files_id_fk FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
--     CONSTRAINT share_type_id_fk FOREIGN KEY(share_type_id) REFERENCES share_type(id) ON DELETE CASCADE
-- );
-- COMMENT ON CONSTRAINT share_by_pk ON share_by IS 'No duplicate share type on a single file';

-------------------------------------------------------------------------------
-- Table of File Permission Types
-------------------------------------------------------------------------------
CREATE SEQUENCE file_permission_s START WITH 1000 INCREMENT BY 1;
CREATE TABLE file_permission (
    id bigint NOT NULL DEFAULT nextval('file_permission_s'),
    title text NOT NULL,
    CONSTRAINT permission_pk PRIMARY KEY(id),
    CONSTRAINT title_u UNIQUE(title)
);
ALTER SEQUENCE file_permission_s OWNED BY file_permission.id;
INSERT INTO file_permission(title) VALUES
    ('OWNER'),
    ('VIEW'),
    ('ANONYMOUS'),
    ('LINK_SHARE');

-------------------------------------------------------------------------------
-- Table of User Permission on File
-------------------------------------------------------------------------------
CREATE TABLE user_file_permission (
    file_id uuid NOT NULL,
    user_id uuid,
    file_permission_id bigint NOT NULL,
    CONSTRAINT user_file_permission_pk UNIQUE(file_id, user_id),
    CONSTRAINT file_id_fk FOREIGN KEY(file_id) REFERENCES file(id) ON DELETE CASCADE,
    CONSTRAINT user_id_fk FOREIGN KEY(user_id) REFERENCES app_user(id) ON DELETE CASCADE,
    CONSTRAINT file_permission_id_fk FOREIGN KEY(file_permission_id) REFERENCES file_permission(id) ON DELETE CASCADE
);
-- One NULL user_id per File (for anonymous/link_share)
CREATE UNIQUE INDEX user_file_permission_one_null_index ON user_file_permission (file_id, (user_id IS NULL)) WHERE user_id IS NULL;

-------------------------------------------------------------------------------
-- Table of Shared Files
-------------------------------------------------------------------------------
-- CREATE TABLE shared_files (
--     id uuid DEFAULT unique_uuid('shared_files'),
--     file_id uuid NOT NULL,
--     user_id uuid NOT NULL,
--     -- shared_user_id uuid NOT NULL,
--     CONSTRAINT shared_files_id_pk PRIMARY KEY(id),
--     CONSTRAINT file_id_fk FOREIGN KEY(file_id) REFERENCES files(id) ON DELETE CASCADE,
--     CONSTRAINT user_id_fk FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
--     CONSTRAINT onetime_share UNIQUE(file_id, user_id)
-- );


-------------------------------------------------------------------------------
-- View of Accessible files
-------------------------------------------------------------------------------
-- CREATE OR REPLACE VIEW file_access AS
--     -- For Users to access their own files
--     SELECT u.id AS user_id, u.username AS username, owner.id AS owner_id, owner.username AS owner_username, f.id AS file_id, f.filename
--         FROM app_user AS u 
--         JOIN user_file_permission AS ufp ON ufp.user_id = u.id
--         JOIN file AS f ON f.id = ufp.file_id
--         JOIN 
--             (SELECT u2.id, u2.username, ufp2.file_id
--                 FROM app_user AS u2 
--                 JOIN user_file_permission AS ufp2 ON ufp2.user_id = u2.id 
--                 WHERE ufp2.file_permission_id = (SELECT id FROM file_permission WHERE title = 'OWNER'))
--             AS owner ON owner.file_id = f.id
--         ORDER BY user_id, owner_id, file_id;
        -- UNION
    -- -- For Users to access shared content
    -- SELECT shf.user_id AS user_id, shu.username AS username, u.id AS owner_id, u.username AS owner_username, f.id AS file_id, f.filename
    --     FROM files AS f
    --     JOIN shared_files AS shf ON f.id = shf.file_id
    --     JOIN users as u ON u.id = f.user_id
    --     JOIN users as shu ON shu.id = shf.user_id
    --     UNION
    -- -- For Files with anonymous access
    -- SELECT NULL AS user_id, NULL AS username, u.id AS owner_id, u.username AS owner_username, f.id AS file_id, f.filename
    --     FROM files AS f
    --     JOIN users AS u ON u.id = f.user_id
    --     JOIN share_by AS sb ON f.id = sb.file_id
    --     WHERE sb.share_type_id = (SELECT id FROM share_type WHERE title = 'ANONYMOUS')
    -- ORDER BY user_id, owner_id, file_id;
-- CREATE OR REPLACE VIEW file_access AS
--     -- For Users to access their own files
--     SELECT u.id AS user_id, u.username AS username, u.id AS owner_id, u.username AS owner_username, f.id AS file_id, f.filename
--         FROM users AS u 
--         JOIN files AS f ON u.id = f.user_id
--         UNION
--     -- For Users to access shared content
--     SELECT shf.user_id AS user_id, shu.username AS username, u.id AS owner_id, u.username AS owner_username, f.id AS file_id, f.filename
--         FROM files AS f
--         JOIN shared_files AS shf ON f.id = shf.file_id
--         JOIN users as u ON u.id = f.user_id
--         JOIN users as shu ON shu.id = shf.user_id
--         UNION
--     -- For Files with anonymous access
--     SELECT NULL AS user_id, NULL AS username, u.id AS owner_id, u.username AS owner_username, f.id AS file_id, f.filename
--         FROM files AS f
--         JOIN users AS u ON u.id = f.user_id
--         JOIN share_by AS sb ON f.id = sb.file_id
--         WHERE sb.share_type_id = (SELECT id FROM share_type WHERE title = 'ANONYMOUS')
--     ORDER BY user_id, owner_id, file_id;

-------------------------------------------------------------------------------
-- Query Accessible Files for a User 
-------------------------------------------------------------------------------
-- CREATE OR REPLACE FUNCTION user_file_access (userid uuid)
-- RETURNS SETOF file_access
-- LANGUAGE plpgsql
-- AS $$
-- BEGIN
--     IF (userid IS NOT NULL) THEN
--         RETURN QUERY
--             SELECT * FROM file_access WHERE user_id = userid;
--     ELSE
--         RETURN QUERY
--             SELECT * FROM file_access WHERE user_id IS NULL;
--     END IF;
-- END; $$;

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
-- SELECT * FROM file_access;
-- SELECT * FROM user_file_access((SELECT id FROM app_user WHERE username = 'admin'));