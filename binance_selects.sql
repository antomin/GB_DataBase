# Топ 10 пользователей по количеству открытых ордеров.
SELECT CONCAT(ac.firstname, ' ', ac.lastname) AS Name, COUNT(*) AS Orders
FROM traiding_orders AS tror
JOIN accounts AS ac ON ac.id = tror.account_id
WHERE tror.is_closed = 0
GROUP BY Name
ORDER BY Orders DESC
LIMIT 10;

# Вывод id пользователей, которые выводили средства на кошелёк PayPal
SELECT id
FROM fiat_orders
WHERE type_order = 'withdraw' AND
	is_closed = 1 AND
	payment_method_id IN (SELECT id FROM payment_methods WHERE payment_type = 2);

# Список открытых криптокошельков активных пользователей
SELECT CONCAT(ac.firstname, ' ', ac.lastname) AS Name, co.coin_code AS Coin, balance AS Balance
FROM wallets AS wa
JOIN accounts AS ac ON ac.id = wa.account_id 
JOIN coins AS co ON co.id = wa.coin_id
WHERE ac.is_blocked = 0
ORDER BY Name;

# Показать баланс кошельков пользователя с id = 10
SET @user_id = 10;

SELECT co.coin_code AS walet, ROUND(balance, 3) AS balance
FROM wallets AS wa
JOIN accounts AS ac ON ac.id = wa.account_id 
JOIN coins AS co ON co.id = wa.coin_id
WHERE ac.id = @user_id
UNION
SELECT pt.name , pm.balance 
FROM payment_methods AS pm
JOIN payment_methods_type AS pt ON pm.payment_type = pt.id 
WHERE pm.account_id = @user_id;

