CREATE TABLE recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    from_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    to_user_id UUID NULL REFERENCES users(id) ON DELETE CASCADE,
    mushroom_id UUID NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT no_self_recommendation CHECK (from_user_id <> to_user_id)
);

CREATE INDEX ON recommendations (to_user_id, status);
CREATE INDEX ON recommendations (from_user_id);
