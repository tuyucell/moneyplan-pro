-- ============================================================
-- DEBUG SCRIPT: Neden "0 Ay" Nakit Ömrü Çıkıyor?
-- ============================================================
-- Bu scripti çalıştırırken 'YOUR_USER_ID' kısmını kendi ID'nizle değiştirin
-- veya Supabase SQL Editor'de bir fonksiyon içinde çağırın.

-- 1. TOPLAM ÇEKİLEBİLİR NAKİT VARLIĞINIZ (Balance)
-- Engine bunu "Nakit Gücü" olarak görür.
SELECT 
    id as account_id, 
    account_name, 
    balance, 
    currency 
FROM user_bank_accounts 
-- WHERE user_id = '...'  <-- Filtreleyerek bakın
ORDER BY balance DESC;

-- 2. ORTALAMA AYLIK GİDER (Burn Rate)
-- Engine'in "Hız" olarak gördüğü veri. Son 3 ayın ortalaması.
SELECT 
    date_trunc('month', date)::DATE as month, 
    SUM(amount) as total_expense_monthly
FROM user_transactions
WHERE type = 'expense'
-- AND user_id = '...'
AND date > NOW() - INTERVAL '3 months'
GROUP BY 1
ORDER BY 1 DESC;

-- 3. HARCAMA KIRILIMI (Category Breakdown)
-- "Kira ve Ulaşım" diyorsunuz, ama veritabanında ne kayıtlı?
-- Burası "Food" veya "Other" ile doluysa Engine onu baz alır.
SELECT 
    category_id, 
    COUNT(*) as islem_sayisi,
    SUM(amount) as toplam_tutar,
    ROUND(SUM(amount) / (SELECT SUM(amount) FROM user_transactions WHERE type='expense' -- AND user_id='...'
    ) * 100, 1) as yuzde_pay
FROM user_transactions
WHERE type = 'expense'
-- AND user_id = '...'
AND date > NOW() - INTERVAL '3 months'
GROUP BY 1
ORDER BY 3 DESC;

-- 4. GELİR KONTROLÜ (Income Check)
-- "Deficit Alert" buna bakıyor: (Ortalama Gider > Bu Ayki Gelir) ise uyarı verir.
SELECT 
    'Current Month Income' as metric,
    COALESCE(SUM(amount), 0) as value
FROM user_transactions 
WHERE type = 'income' 
AND date >= date_trunc('month', CURRENT_DATE)
-- AND user_id = '...'

UNION ALL

SELECT 
    'Avg Monthly Expense (Burn)' as metric,
    COALESCE(AVG(monthly_total), 0) as value
FROM (
    SELECT date_trunc('month', date), SUM(amount) as monthly_total
    FROM user_transactions
    WHERE type = 'expense' 
    AND date > NOW() - INTERVAL '3 months'
    -- AND user_id = '...'
    GROUP BY 1
) burn;

-- 5. MANUEL HESAPLAMA KONTROLÜ
-- (Toplam Nakit / Son 3 Ay Ortalama Gider) = Tahmini Ömür
