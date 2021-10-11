# Курсы монет
CREATE OR REPLACE VIEW courses AS
	SELECT CONCAT(c1.coin_code, ' / ', c2.coin_code) AS pair, ROUND(tp.pair_course, 3) AS cource
	FROM traiding_pairs AS tp
	JOIN coins AS c1 ON tp.coin_id_a = c1.id 
	JOIN coins AS c2 ON tp.coin_id_b = c2.id
	ORDER BY pair;

# Открытые ордера на покупку/продажу монет
CREATE OR REPLACE VIEW open_orders AS
	SELECT CONCAT(ac.firstname, ' ', ac.lastname) AS name, CONCAT(c1.coin_code, ' / ', c2.coin_code) AS pair, tro.order_sum AS 'sum', tro.type_order AS 'type', ROUND(tp.pair_course, 3) AS course, tro.created_at 
	FROM traiding_orders AS tro
	JOIN accounts AS ac ON tro.account_id = ac.id
	JOIN traiding_pairs AS tp ON tro.traiding_pair_id = tp.id
	JOIN coins AS c1 ON tp.coin_id_a = c1.id 
	JOIN coins AS c2 ON tp.coin_id_b = c2.id
	WHERE is_closed = 0
	ORDER BY tro.created_at DESC;
