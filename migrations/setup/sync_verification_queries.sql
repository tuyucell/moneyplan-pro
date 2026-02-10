-- Supabase Veri Senkronizasyonu Doğrulama Sorguları

-- 1. Tüm Tablolardaki Veri Sayılarını Kontrol Et
SELECT 
    (SELECT COUNT(*) FROM user_watchlists) as total_watchlist_items,
    (SELECT COUNT(*) FROM user_portfolio_assets) as total_portfolio_assets,
    (SELECT COUNT(*) FROM user_bank_accounts) as total_bank_accounts,
    (SELECT COUNT(*) FROM user_transactions) as total_transactions;

-- 2. Belirli Bir Kullanıcının Özet Verisini Getir
-- Not: target_user_id kısmına gerçek bir UUID yazın
-- SELECT id FROM users LIMIT 1; -- Örnek bir ID almak için kullanabilirsiniz.

WITH target_user AS (
    SELECT id FROM users WHERE email = 'test@example.com' -- Buraya kontrol etmek istediğiniz e-postayı yazın
)
SELECT 
    'Watchlist' as type, symbol, asset_name as name, NULL as amount
FROM user_watchlists WHERE user_id IN (SELECT id FROM target_user)
UNION ALL
SELECT 
    'Portfolio' as type, symbol, name, quantity as amount
FROM user_portfolio_assets WHERE user_id IN (SELECT id FROM target_user)
UNION ALL
SELECT 
    'Transaction' as type, category_id as symbol, description as name, amount
FROM user_transactions WHERE user_id IN (SELECT id FROM target_user);

-- 3. Hangi Kullanıcı En Aktif? (Veri sayısına göre)
SELECT 
    u.email,
    COUNT(DISTINCT w.id) as watchlist_count,
    COUNT(DISTINCT p.id) as portfolio_count,
    COUNT(DISTINCT t.id) as transaction_count
FROM users u
LEFT JOIN user_watchlists w ON u.id = w.user_id
LEFT JOIN user_portfolio_assets p ON u.id = p.user_id
LEFT JOIN user_transactions t ON u.id = t.user_id
GROUP BY u.id, u.email
ORDER BY transaction_count DESC, portfolio_count DESC;

-- 4. En Çok İzlenen (Watchlist) Varlıklar
SELECT symbol, asset_name, COUNT(*) as watchers
FROM user_watchlists
GROUP BY symbol, asset_name
ORDER BY watchers DESC
LIMIT 10;
