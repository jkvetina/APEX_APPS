CREATE TABLE pay_secrets (
    id                              VARCHAR2(64),
    value                           VARCHAR2(512),
    created_by                      VARCHAR2(128),
    created_at                      DATE,
    --
    CONSTRAINT pk_pay_secrets
        PRIMARY KEY (id)
);
--
COMMENT ON TABLE pay_secrets IS '';
--
COMMENT ON COLUMN pay_secrets.id        IS '';
COMMENT ON COLUMN pay_secrets.value     IS '';

