--Creating a view that we can easily query to get transactions for a specific card holder
CREATE VIEW  card_holder_transactions AS
SELECT card_holder.id
,card_holder.name
,credit_card.card
,transaction.date
,transaction.amount
FROM card_holder
LEFT JOIN credit_card
ON card_holder.id = credit_card.cardholder_id
LEFT JOIN transaction
ON credit_card.card = transaction.card
--Querying view to get all transaction of card holder 'Shane Shaffer' as an example
SELECT * FROM card_holder_transactions WHERE name = 'Shane Shaffer'

-- Using subqueries to find the transactions for a given card holder
SELECT * FROM transaction 
WHERE transaction.card IN(
	SELECT credit_card.card FROM credit_card 
	WHERE credit_card.cardholder_id IN(
		SELECT card_holder.id FROM card_holder 
		WHERE card_holder.name = 'Shane Shaffer'
	) 
)

--Getting the highest transaction amount for transaction
--occuring during 7 A.M. to 9 A.M. 
CREATE VIEW TOP_TRANSACTIONS_DURING_PERIOD AS
SELECT * FROM transaction
WHERE CAST(transaction.date AS time) BETWEEN '07:00:00' AND '09:00:00'
ORDER BY amount DESC
LIMIT 100;

--Getting the average amount spent per merchant
CREATE VIEW AVG_SPENDING_PER_MERCHANT AS
SELECT id_merchant
,AVG(amount) AS avg_amount
FROM transaction
GROUP BY id_merchant;

--Joining the highest transaction amounts during 7 A.M. to 9 A.M.
--with the average amount spent per merchant
SELECT TOP_TRANSACTIONS_DURING_PERIOD.* 
,AVG_SPENDING_PER_MERCHANT.avg_amount
FROM TOP_TRANSACTIONS_DURING_PERIOD
LEFT JOIN AVG_SPENDING_PER_MERCHANT
ON TOP_TRANSACTIONS_DURING_PERIOD.id_merchant = AVG_SPENDING_PER_MERCHANT.id_merchant
ORDER BY TOP_TRANSACTIONS_DURING_PERIOD.amount DESC;

--Getting the count of transactions less than 2 for each card holder
SELECT id
,COUNT(amount) as num_transaction_less_than_2
FROM card_holder_transactions
WHERE amount < 2
GROUP BY id
ORDER BY num_transaction_less_than_2 DESC;

--getting the top 5 merchants with the most transactions
SELECT transaction.id_merchant
,merchant.name
,COUNT(transaction.amount) AS count_of_transactions
FROM transaction
LEFT JOIN merchant
ON  transaction.id_merchant = merchant.id
GROUP BY id_merchant
,merchant.name
ORDER BY count_of_transactions DESC
LIMIT 5;