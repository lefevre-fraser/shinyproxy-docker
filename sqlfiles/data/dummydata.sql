INSERT INTO app_user (username) VALUES
    ('bob'),
    ('admin')
RETURNING *;

INSERT INTO file (filename, title) VALUES
    ('somefile.zip', 'Cool Title'),
    ('somebobfile.zip', 'Bob Title'),
    ('someadminfile.zip', 'Cool Admin Title'),
    ('someadminfile2.zip', 'Cool 2 Title'),
    ('someadminfile3.zip', 'Cool 3 Title')
RETURNING *;

INSERT INTO user_file_permission (user_id, file_id, file_permission_id) VALUES
    (
        (SELECT id from app_user WHERE username = 'bob'),
        (SELECT id from file WHERE filename = 'somefile.zip'),
        (SELECT id from file_permission WHERE title = 'OWNER')
    ),
    (
        (SELECT id from app_user WHERE username = 'bob'),
        (SELECT id from file WHERE filename = 'somebobfile.zip'),
        (SELECT id from file_permission WHERE title = 'OWNER')
    ),
    (
        (SELECT id from app_user WHERE username = 'admin'),
        (SELECT id from file WHERE filename = 'someadminfile.zip'),
        (SELECT id from file_permission WHERE title = 'OWNER')
    ),
    (
        (SELECT id from app_user WHERE username = 'admin'),
        (SELECT id from file WHERE filename = 'someadminfile2.zip'),
        (SELECT id from file_permission WHERE title = 'OWNER')
    ),
    (
        (SELECT id from app_user WHERE username = 'admin'),
        (SELECT id from file WHERE filename = 'someadminfile3.zip'),
        (SELECT id from file_permission WHERE title = 'OWNER')
    )
RETURNING *;

INSERT INTO user_file_permission (user_id, file_id, file_permission_id) VALUES
    (
        (SELECT id from app_user WHERE username = 'admin'),
        (SELECT id from file WHERE filename = 'somefile.zip'),
        (SELECT id from file_permission WHERE title = 'VIEW')
    ),
    (
        (SELECT id from app_user WHERE username = 'admin'),
        (SELECT id from file WHERE filename = 'somebobfile.zip'),
        (SELECT id from file_permission WHERE title = 'VIEW')
    ),
    (
        (SELECT id from app_user WHERE username = 'bob'),
        (SELECT id from file WHERE filename = 'someadminfile.zip'),
        (SELECT id from file_permission WHERE title = 'VIEW')
    ),
    (
        (SELECT id from app_user WHERE username = 'bob'),
        (SELECT id from file WHERE filename = 'someadminfile2.zip'),
        (SELECT id from file_permission WHERE title = 'VIEW')
    ),
    (
        (SELECT id from app_user WHERE username = 'bob'),
        (SELECT id from file WHERE filename = 'someadminfile3.zip'),
        (SELECT id from file_permission WHERE title = 'VIEW')
    ),
    (
        NULL,
        (SELECT id from file WHERE filename = 'someadminfile3.zip'),
        (SELECT id from file_permission WHERE title = 'ANONYMOUS')
    )
RETURNING *;

SELECT * FROM file_access;