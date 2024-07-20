#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=user_info -t --no-align -c"
session_guesses=0
echo "Enter your username:"
read username

# user guess function 
user_guess() { 
  computer_num=$((1 + $RANDOM % 1001))
  echo "Guess the secret number between 1 and 1000:"
  read user_num
  ((session_guesses++))
  while ((computer_num != user_num))
  do
    # check if user typed in number greater than computer_num and if integer 
    if [[ -z ${user_num//[0-9]/} ]]
    then
      if (( $user_num > $computer_num ))
      then
        echo "It's lower than that, guess again:"
        read user_num
        (( session_guesses++ ))
      else
        echo "It's higher than that, guess again:"
        read user_num
        (( session_guesses++ ))
      fi
    else
      echo "That is not an integer, guess again:"
      read user_num
      (( session_guesses++ ))
    fi
  done
  stored_best_guesses=$($PSQL "SELECT best_game_guesses FROM user_information WHERE name='$username'")
  stored_games_played=$($PSQL "SELECT games_played FROM user_information WHERE name='$username'")
  if [[ $session_guesses -le $stored_best_guesses || $stored_best_guesses -eq 0 ]]
  then
    $PSQL "UPDATE user_information SET best_game_guesses=$session_guesses WHERE name='$username'" > /dev/null 2>&1
  fi
  # update user games played
  new_games_played=$(( stored_games_played + 1))
  $PSQL "UPDATE user_information SET games_played=$new_games_played WHERE name='$username'" > /dev/null 2>&1
  echo "You guessed it in $session_guesses tries. The secret number was $computer_num. Nice job!"
}

# check if user has played before
if [[ -z $($PSQL "SELECT name FROM user_information WHERE name='$username'") ]]
then
  #  insert user info if they have never played before
   echo "Welcome, $username! It looks like this is your first time here."
   $PSQL "INSERT INTO user_information(games_played, name, best_game_guesses) VALUES(0, '$username', 0)" > /dev/null 2>&1
   user_guess
else
  # if they are in the database, greet them
  games_played=$($PSQL "SELECT games_played FROM user_information WHERE name='$username'")
  best_game=$($PSQL "SELECT best_game_guesses FROM user_information WHERE name='$username'")
  echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
  user_guess
fi