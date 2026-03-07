#!/bin/sh
# Restore Supabase backups into local PostgreSQL
# Disables FK constraints during restore to avoid ordering issues

set -e

echo "========================================="
echo "Restoring Core Service Database (eventbn)"
echo "========================================="

# Clear existing data
psql -U eventbn -d eventbn <<'EOSQL'
SET session_replication_role = 'replica';
TRUNCATE TABLE ticket_purchase CASCADE;
TRUNCATE TABLE payment CASCADE;
TRUNCATE TABLE monthly_analytics CASCADE;
TRUNCATE TABLE "Search_Log" CASCADE;
TRUNCATE TABLE "Event" CASCADE;
TRUNCATE TABLE "Organization" CASCADE;
TRUNCATE TABLE "User" CASCADE;
SET session_replication_role = 'origin';
EOSQL
echo "[OK] Cleared seeded data from eventbn"

# Extract COPY blocks for public schema
echo "Extracting public schema data from core backup..."
awk '
  /^COPY public\./ { printing=1 }
  printing { print }
  /^\\.$/ && printing { printing=0 }
' /tmp/core-backup.sql > /tmp/core-public-data.sql
echo "Lines extracted: $(wc -l < /tmp/core-public-data.sql)"

# Restore with FK checks disabled
psql -U eventbn -d eventbn <<'EOSQL'
SET session_replication_role = 'replica';
\i /tmp/core-public-data.sql
SET session_replication_role = 'origin';
EOSQL
echo "[OK] Core service data restored"

# Fix sequences (skip UUID-based ones like payment_id)
psql -U eventbn -d eventbn <<'EOSQL'
SELECT setval(pg_get_serial_sequence('"User"', 'user_id'), COALESCE((SELECT MAX(user_id) FROM "User"), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('"Event"', 'event_id'), COALESCE((SELECT MAX(event_id) FROM "Event"), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('"Organization"', 'organization_id'), COALESCE((SELECT MAX(organization_id) FROM "Organization"), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('"Search_Log"', 'log_id'), COALESCE((SELECT MAX(log_id) FROM "Search_Log"), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('ticket_purchase', 'ticket_id'), COALESCE((SELECT MAX(ticket_id) FROM ticket_purchase), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('monthly_analytics', 'id'), COALESCE((SELECT MAX(id) FROM monthly_analytics), 0) + 1, false);
EOSQL
echo "[OK] Sequences reset"

# Show counts
psql -U eventbn -d eventbn -c "
  SELECT 'Users' as table_name, COUNT(*) FROM \"User\"
  UNION ALL SELECT 'Events', COUNT(*) FROM \"Event\"
  UNION ALL SELECT 'Organizations', COUNT(*) FROM \"Organization\"
  UNION ALL SELECT 'Payments', COUNT(*) FROM payment
  UNION ALL SELECT 'Tickets', COUNT(*) FROM ticket_purchase
  UNION ALL SELECT 'Search_Logs', COUNT(*) FROM \"Search_Log\"
  UNION ALL SELECT 'Analytics', COUNT(*) FROM monthly_analytics;
"

echo ""
echo "============================================"
echo "Restoring Post Service Database (eventbn_posts)"
echo "============================================"

# Clear existing data in post DB
psql -U eventbn -d eventbn_posts <<'EOSQL'
SET session_replication_role = 'replica';
TRUNCATE TABLE "CommentLike" CASCADE;
TRUNCATE TABLE "PostLike" CASCADE;
TRUNCATE TABLE "Comment" CASCADE;
TRUNCATE TABLE "Post" CASCADE;
TRUNCATE TABLE users CASCADE;
SET session_replication_role = 'origin';
EOSQL
echo "[OK] Cleared post DB data"

# Extract COPY blocks for post backup
echo "Extracting public schema data from post backup..."
awk '
  /^COPY public\./ { printing=1 }
  printing { print }
  /^\\.$/ && printing { printing=0 }
' /tmp/post-backup.sql > /tmp/post-public-data.sql
echo "Lines extracted: $(wc -l < /tmp/post-public-data.sql)"

# Restore with FK checks disabled
psql -U eventbn -d eventbn_posts <<'EOSQL'
SET session_replication_role = 'replica';
\i /tmp/post-public-data.sql
SET session_replication_role = 'origin';
EOSQL
echo "[OK] Post service data restored"

# Show counts for post DB
psql -U eventbn -d eventbn_posts -c "
  SELECT 'Posts' as table_name, COUNT(*) FROM posts
  UNION ALL SELECT 'Comments', COUNT(*) FROM comments
  UNION ALL SELECT 'Reactions', COUNT(*) FROM reactions;
" 2>/dev/null || echo "Could not count post tables (table name mismatch is OK)"

echo ""
echo "========================================="
echo "Restore complete!"
echo "========================================="
