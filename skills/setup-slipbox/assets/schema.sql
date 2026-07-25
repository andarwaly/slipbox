-- idea.db — every note is an idea: extracted (raw), literature, reference, or evergreen.
-- Two tables, not three, not one: `seeds` holds raw+literature+reference (same row across
-- its lifecycle); `evergreen` is its own table (no seed precursor, plural citations).
-- See discussion/note-taking-skills/grill-decisions-2026-07-23.md for full rationale.

PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA busy_timeout = 5000;

CREATE TABLE seeds (
  slug            TEXT PRIMARY KEY,      -- renamed at write time: question-slug -> confirmed-claim-slug
  resource        TEXT NOT NULL,         -- first-seen resource; additional resources touching a
                                          -- reference term go through `links` (rel_type: 'extends'),
                                          -- not a second resource column
  type            TEXT NOT NULL CHECK (type IN ('raw','literature','reference')),
  target_type     TEXT NOT NULL CHECK (target_type IN ('literature','reference')),
                                          -- set at surface time; distinct from `type`, which stays
                                          -- 'raw' until discussion resolves it
  status          TEXT NOT NULL CHECK (status IN ('to-discuss','discussing','discussed','dismissed')),
  discussion_path TEXT,                  -- points to the resume .md; NULL unless status='discussing'
  origin          TEXT NOT NULL CHECK (origin IN ('surface','discussion')),
  reason          TEXT NOT NULL,
  note_path       TEXT,
  created_at      TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX idx_seeds_resource      ON seeds(resource);
CREATE INDEX idx_seeds_target_status ON seeds(target_type, status);

CREATE TABLE evergreen (
  slug            TEXT PRIMARY KEY,      -- provisional draft-prefixed slug renamed at write time
  status          TEXT NOT NULL CHECK (status IN ('to-discuss','discussing','discussed','dismissed')),
  discussion_path TEXT,
  note_path       TEXT,                  -- nullable: placeholder row exists before anything is written
  iteration       INTEGER NOT NULL DEFAULT 1,
  created_at      TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX idx_evergreen_status ON evergreen(status);

CREATE TABLE links (
  source_id  TEXT NOT NULL,
  target_id  TEXT NOT NULL,
  rel_type   TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  PRIMARY KEY (source_id, target_id, rel_type)
);
CREATE INDEX idx_links_source ON links(source_id, rel_type);
CREATE INDEX idx_links_target ON links(target_id, rel_type);

CREATE VIEW stale_seeds AS
SELECT slug, resource, reason, created_at,
       CAST(julianday('now') - julianday(created_at) AS INTEGER) AS days_stale
FROM seeds
WHERE status = 'to-discuss'
ORDER BY days_stale DESC;

CREATE VIRTUAL TABLE seeds_fts USING fts5(
  slug UNINDEXED, reason, content='seeds', content_rowid='rowid'
);
CREATE TRIGGER trg_seeds_fts_insert AFTER INSERT ON seeds BEGIN
  INSERT INTO seeds_fts(rowid, slug, reason) VALUES (NEW.rowid, NEW.slug, NEW.reason);
END;
CREATE TRIGGER trg_seeds_fts_update AFTER UPDATE ON seeds BEGIN
  UPDATE seeds_fts SET reason = NEW.reason WHERE rowid = OLD.rowid;
END;
CREATE TRIGGER trg_seeds_fts_delete AFTER DELETE ON seeds BEGIN
  DELETE FROM seeds_fts WHERE rowid = OLD.rowid;
END;

CREATE TRIGGER trg_seeds_updated_at
AFTER UPDATE ON seeds
FOR EACH ROW
BEGIN
  UPDATE seeds SET updated_at = datetime('now') WHERE slug = OLD.slug;
END;

CREATE TRIGGER trg_evergreen_updated_at
AFTER UPDATE ON evergreen
FOR EACH ROW
BEGIN
  UPDATE evergreen SET updated_at = datetime('now') WHERE slug = OLD.slug;
END;
