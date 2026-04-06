-- HealthPulse CMS Schema
-- Multi-tenant content management system for healthcare publishing

-- =============================================================================
-- ENUMS
-- =============================================================================

CREATE TYPE post_status AS ENUM ('draft', 'in_review', 'approved', 'published', 'archived');
CREATE TYPE content_type AS ENUM ('article', 'quick_post', 'opinion', 'interview', 'case_study');
CREATE TYPE cms_role AS ENUM ('admin', 'editor', 'author', 'reviewer');

-- =============================================================================
-- TENANTS
-- =============================================================================

CREATE TABLE tenants (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL,
    slug        TEXT NOT NULL UNIQUE,
    domain      TEXT,
    settings    JSONB DEFAULT '{}' NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at  TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- =============================================================================
-- CMS USERS (admins, editors, authors, reviewers)
-- =============================================================================

CREATE TABLE cms_users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    email           TEXT NOT NULL,
    password_hash   TEXT NOT NULL,
    name            TEXT NOT NULL,
    role            cms_role NOT NULL DEFAULT 'author',
    slug            TEXT NOT NULL,
    avatar          TEXT,
    bio             TEXT,
    credentials     TEXT,       -- "MD, MPH" for medical reviewers
    location        TEXT,
    website         TEXT,
    twitter         TEXT,
    linkedin        TEXT,
    is_active       BOOLEAN DEFAULT true NOT NULL,
    created_at      TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at      TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE(tenant_id, email),
    UNIQUE(tenant_id, slug)
);

-- =============================================================================
-- CATEGORIES
-- =============================================================================

CREATE TABLE categories (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name                    TEXT NOT NULL,
    slug                    TEXT NOT NULL,
    description             TEXT,
    color                   TEXT DEFAULT '#0f766e',
    icon                    TEXT,
    sort_order              INT DEFAULT 0 NOT NULL,
    requires_medical_review BOOLEAN DEFAULT false NOT NULL,
    parent_id               UUID REFERENCES categories(id) ON DELETE SET NULL,
    created_at              TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at              TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE(tenant_id, slug)
);

-- =============================================================================
-- TAGS
-- =============================================================================

CREATE TABLE tags (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name        TEXT NOT NULL,
    slug        TEXT NOT NULL,
    UNIQUE(tenant_id, slug)
);

-- =============================================================================
-- POSTS
-- =============================================================================

CREATE TABLE posts (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    title                   TEXT NOT NULL,
    slug                    TEXT NOT NULL,
    content                 TEXT NOT NULL DEFAULT '',    -- Markdown source
    html                    TEXT,                        -- Rendered HTML (cached)
    excerpt                 TEXT,
    category_id             UUID NOT NULL REFERENCES categories(id),
    author_id               UUID NOT NULL REFERENCES cms_users(id),
    status                  post_status DEFAULT 'draft' NOT NULL,
    content_type            content_type DEFAULT 'article' NOT NULL,
    featured                BOOLEAN DEFAULT false NOT NULL,
    feature_image           TEXT,
    feature_image_alt       TEXT,
    feature_image_caption   TEXT,
    reading_time            INT DEFAULT 0 NOT NULL,
    -- SEO
    meta_title              TEXT,
    meta_description        TEXT,
    og_image                TEXT,
    canonical_url           TEXT,
    noindex                 BOOLEAN DEFAULT false NOT NULL,
    -- Medical review
    medical_reviewer_id     UUID REFERENCES cms_users(id),
    medical_review_date     TIMESTAMPTZ,
    medical_review_notes    TEXT,
    -- Full-text search
    search_vector           TSVECTOR,
    -- Timestamps
    published_at            TIMESTAMPTZ,
    created_at              TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at              TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE(tenant_id, slug)
);

-- =============================================================================
-- POST-TAG JUNCTION
-- =============================================================================

CREATE TABLE post_tags (
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    tag_id  UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (post_id, tag_id)
);

-- =============================================================================
-- POST REVISIONS (version history)
-- =============================================================================

CREATE TABLE post_revisions (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id     UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    title       TEXT NOT NULL,
    content     TEXT NOT NULL,
    editor_id   UUID NOT NULL REFERENCES cms_users(id),
    created_at  TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- =============================================================================
-- MEDIA LIBRARY
-- =============================================================================

CREATE TABLE media (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    filename        TEXT NOT NULL,
    original_name   TEXT NOT NULL,
    mime_type       TEXT NOT NULL,
    size_bytes      BIGINT NOT NULL,
    url             TEXT NOT NULL,
    alt_text        TEXT,
    uploaded_by     UUID NOT NULL REFERENCES cms_users(id),
    created_at      TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- =============================================================================
-- NEWSLETTER SUBSCRIBERS
-- =============================================================================

CREATE TABLE subscribers (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    email           TEXT NOT NULL,
    name            TEXT,
    subscribed_at   TIMESTAMPTZ DEFAULT now() NOT NULL,
    confirmed       BOOLEAN DEFAULT false NOT NULL,
    unsubscribed_at TIMESTAMPTZ,
    UNIQUE(tenant_id, email)
);

-- =============================================================================
-- PAGE VIEW ANALYTICS
-- =============================================================================

CREATE TABLE page_views (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    post_id     UUID REFERENCES posts(id) ON DELETE SET NULL,
    path        TEXT NOT NULL,
    referrer    TEXT,
    country     TEXT,
    viewed_at   TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- =============================================================================
-- API KEYS (headless access for Astro build)
-- =============================================================================

CREATE TABLE api_keys (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name        TEXT NOT NULL,
    key_hash    TEXT NOT NULL,
    permissions TEXT[] DEFAULT '{read}' NOT NULL,
    created_by  UUID NOT NULL REFERENCES cms_users(id),
    last_used_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- =============================================================================
-- INDEXES
-- =============================================================================

-- Full-text search
CREATE INDEX idx_posts_search ON posts USING GIN(search_vector);

-- Common query patterns
CREATE INDEX idx_posts_tenant_status ON posts(tenant_id, status);
CREATE INDEX idx_posts_tenant_published ON posts(tenant_id, published_at DESC) WHERE status = 'published';
CREATE INDEX idx_posts_tenant_slug ON posts(tenant_id, slug);
CREATE INDEX idx_posts_category ON posts(category_id);
CREATE INDEX idx_posts_author ON posts(author_id);
CREATE INDEX idx_categories_tenant ON categories(tenant_id, sort_order);
CREATE INDEX idx_tags_tenant ON tags(tenant_id);
CREATE INDEX idx_media_tenant ON media(tenant_id, created_at DESC);
CREATE INDEX idx_subscribers_tenant ON subscribers(tenant_id);
CREATE INDEX idx_page_views_tenant ON page_views(tenant_id, viewed_at DESC);
CREATE INDEX idx_page_views_post ON page_views(post_id, viewed_at DESC);

-- =============================================================================
-- TRIGGERS
-- =============================================================================

-- Auto-update search vector on posts insert/update
CREATE OR REPLACE FUNCTION update_post_search_vector() RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector := to_tsvector('english',
        COALESCE(NEW.title, '') || ' ' ||
        COALESCE(NEW.excerpt, '') || ' ' ||
        COALESCE(NEW.content, '')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_post_search
    BEFORE INSERT OR UPDATE ON posts
    FOR EACH ROW EXECUTE FUNCTION update_post_search_vector();

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at() RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tenants_updated_at BEFORE UPDATE ON tenants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_cms_users_updated_at BEFORE UPDATE ON cms_users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_categories_updated_at BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_posts_updated_at BEFORE UPDATE ON posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- =============================================================================
-- ROW-LEVEL SECURITY
-- =============================================================================

ALTER TABLE cms_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_revisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE media ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscribers ENABLE ROW LEVEL SECURITY;
ALTER TABLE page_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_cms_users ON cms_users
    USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
CREATE POLICY tenant_isolation_categories ON categories
    USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
CREATE POLICY tenant_isolation_tags ON tags
    USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
CREATE POLICY tenant_isolation_posts ON posts
    USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
CREATE POLICY tenant_isolation_post_tags ON post_tags
    USING (post_id IN (SELECT id FROM posts WHERE tenant_id = current_setting('app.tenant_id', true)::UUID));
CREATE POLICY tenant_isolation_post_revisions ON post_revisions
    USING (post_id IN (SELECT id FROM posts WHERE tenant_id = current_setting('app.tenant_id', true)::UUID));
CREATE POLICY tenant_isolation_media ON media
    USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
CREATE POLICY tenant_isolation_subscribers ON subscribers
    USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
CREATE POLICY tenant_isolation_page_views ON page_views
    USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
CREATE POLICY tenant_isolation_api_keys ON api_keys
    USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
