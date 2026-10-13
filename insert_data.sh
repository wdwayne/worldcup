#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

# Build one SQL statement for efficient insertion.
VALUES_SQL=""

while IFS=, read -r year round winner opponent winner_goals opponent_goals
do
  VALUES_SQL="${VALUES_SQL}('${year}','${round}','${winner}','${opponent}',${winner_goals},${opponent_goals}),"
done < <(tail -n +2 games.csv)

# Remove the final comma.
VALUES_SQL="${VALUES_SQL%,}"

SQL="BEGIN;

CREATE TEMP TABLE staging_games (
  year INT,
  round_name VARCHAR(20),
  winner VARCHAR(50),
  opponent VARCHAR(50),
  winner_goals INT,
  opponent_goals INT
);

INSERT INTO staging_games
VALUES ${VALUES_SQL};

INSERT INTO teams(name)
SELECT team_name
FROM (
  SELECT winner AS team_name FROM staging_games
  UNION
  SELECT opponent FROM staging_games
) AS all_teams
ON CONFLICT (name) DO NOTHING;

INSERT INTO games (
  year, round, winner_id, opponent_id,
  winner_goals, opponent_goals
)
SELECT
  sg.year,
  sg.round_name,
  w.team_id,
  o.team_id,
  sg.winner_goals,
  sg.opponent_goals
FROM staging_games sg
JOIN teams w ON w.name = sg.winner
JOIN teams o ON o.name = sg.opponent;

COMMIT;"

$PSQL "$SQL"
