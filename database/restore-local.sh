#!/bin/sh
# Restore Supabase backups into local PostgreSQL
# This script runs inside the Docker container

set -e

echo "========================================="
echo "Restoring Core Service Database (eventbn)"
echo "========================================="

# ---- Core Service DB ----
# First, clear existing data (seeded data) in reverse dependency order
psql -U eventbn -d eventbn -c "
  TRUNCATE TABLE ticket_purchase CASCADE;
  TRUNCATE TABLE payment CASCADE;
  TRUNCATE TABLE monthly_analytics CASCADE;
  TRUNCATE TABLE \"Search_Log\" CASCADE;
  TRUNCATE TABLE \"Event\" CASCADE;
  TRUNCATE TABLE \"Organization\" CASCADE;
  TRUNCATE TABLE \"User\" CASCADE;
"
echo "[OK] Cleared seeded data from eventbn"

# Extract and restore COPY blocks for public schema from core backup
# We need to handle the fact that the backup User table has fewer columns
# than our current schema (which has new billing/2fa columns)

# The backup User columns: user_id, name, email, password_hash, phone_number, profile_picture, is_active, is_email_verified, role, created_at, updated_at
# Our Prisma schema has many more columns, but they all have defaults or are nullable, so this COPY should work

# Use sed/awk to extract only COPY public.* blocks (COPY line + data + \. terminator)
echo "Extracting public schema data from core backup..."
awk '
  /^COPY public\./ { printing=1 }
  printing { print }
  /^\\.$/ && printing { printing=0 }
' /tmp/core-backup.sql > /tmp/core-public-data.sql

echo "Lines extracted: $(wc -l < /tmp/core-public-data.sql)"

# Restore the data
psql -U eventbn -d eventbn < /tmp/core-public-data.sql
echo "[OK] Core service data restored"

# Fix sequences after data import
psql -U eventbn -d eventbn -c "
  SELECT setval('\"User_user_id_seq\"', COALESCE((SELECT MAX(user_id) FROM \"User\"), 0) + 1, false);
  SELECT setval('\"Event_event_id_seq\"', COALESCE((SELECT MAX(event_id) FROM \"Event\"), 0) + 1, false);
  SELECT setval('\"Organization_organization_id_seq\"', COALESCE((SELECT MAX(organization_id) FROM \"Organization\"), 0) + 1, false);
  SELECT setval('\"Search_Log_log_id_seq\"', COALESCE((SELECT MAX(log_id) FROM \"Search_Log\"), 0) + 1, false);
  SELECT setval('payment_payment_id_seq', COALESCE((SELECT MAX(payment_id) FROM payment), 0) + 1, false);
  SELECT setval('ticket_purchase_ticket_id_seq', COALESCE((SELECT MAX(ticket_id) FROM ticket_purchase), 0) + 1, false);
"
echo "[OK] Sequences reset"

# Show counts
psql -U eventbn -d eventbn -c "
  SELECT 'Users' as table_name, COUNT(*) FROM \"User\"
  UNION ALL SELECT 'Events', COUNT(*) FROM \"Event\"
  UNION ALL SELECT 'Organizations', COUNT(*) FROM \"Organization\"
  UNION ALL SELECT 'Payments', COUNT(*) FROM payment
  UNION ALL SELECT 'Tickets', COUNT(*) FROM ticket_purchase
  UNION ALL SELECT 'Search_Logs', COUNT(*) FROM \"Search_Log\"
  UNION ALL SELECT 'Monthly_Analytics', COUNT(*) FROM monthly_analytics;
"

echo ""
echo "============================================"
echo "Restoring Post Service Database (eventbn_posts)"
echo "============================================"

# ---- Post Service DB ----
# Clear existing data
psql -U eventbn -d eventbn_posts -c "
  TRUNCATE TABLE comment_likes CASCADE;
  TRUNCATE TABLE post_likes CASCADE;
  TRUNCATE TABLE comments CASCADE;
  TRUNCATE TABLE posts CASCADE;
  TRUNCATE TABLE users CASCADE;
" 2>/dev/null || psql -U eventbn -d eventbn_posts -c "
  TRUNCATE TABLE comments CASCADE;
  TRUNCATE TABLE posts CASCADE;
" 2>/dev/null || echo "Some tables may not exist yet in post DB, continuing..."

echo "Extracting public schema data from post backup..."
awk '
  /^COPY public\./ { printing=1 }
  printing { print }
  /^\\.$/ && printing { printing=0 }
' /tmp/post-backup.sql > /tmp/post-public-data.sql

echo "Lines extracted: $(wc -l < /tmp/post-public-data.sql)"

# The post backup uses table names: comments, posts, reactions
# Our Prisma schema maps: Post->posts, Comment->comments, reactions->reactions
# But it also has post_likes, comment_likes, users tables
# The backup may not have all tables, so restore what we can

psql -U eventbn -d eventbn_posts < /tmp/post-public-data.sql 2>&1 || echo "Some post data import warnings (expected)"
echo "[OK] Post service data restored"

# Show counts for post DB
psql -U eventbn -d eventbn_posts -c "
  SELECT 'Posts' as table_name, COUNT(*) FROM posts
  UNION ALL SELECT 'Comments', COUNT(*) FROM comments
  UNION ALL SELECT 'Reactions', COUNT(*) FROM reactions;
" 2>/dev/null || echo "Could not count post tables"

echo ""
echo "========================================="
echo "Restore complete!"
echo "========================================="
