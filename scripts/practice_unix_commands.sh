# Lines starts with "#" are just description, they are not commands.
# ----------------------------------------------------------------------
# To practice Unix commands in bash terminal
# ----------------------------------------------------------------------

# Setting up practice directory at unix_practice"
mkdir "unix_practice"
cd "unix_practice"

# Clean out any previous practice data to make the script idempotent.
mkdir data scripts results tmp

# ----------------------------------------------------------------------
# Create sample files for practicing commands
# ----------------------------------------------------------------------

# A simple text file containing repeated fruit names (lower‑case and
# mixed case) to practice grep, sort, uniq and sed commands.
cat > data/fruit.txt   #press enter then copy/paste the content below in the file fruit.txt
apple
banana
Apple
cherry
banana
apple1
apples
Banana
pear
orange
apple
# Read the file
cat  data/fruit.txt

# after pasting the conetnt of the file press ctrl-D

# A file with unsorted numbers (as strings) to practise sorting with
# lexical and numeric options.
cat > data/numbers.txt
3
11
2
8
1
10
4
2
5
#ctrl-D
# Read the file
cat  data/numbers.txt

# A comma‑separated values file for practising cut and sort by
# columns.  Tab separation is left as the default delimiter for cut.
cat > data/people.csv
id,name,age
1,Alice,30
2,Bob,25
3,Carol,27
4,Dave,25
5,Eve,30
#ctrl-D
# Read the file
cat data/people.csv

# A small multi‑line text file to explore head, tail and wc
cat > data/story.txt
Line one: Once upon a time there was a file.
Line two: It contained multiple lines for testing.
Line three: Some lines contain the word apple and banana.
Line four: GREP should find both uppercase and lowercase.
Line five: The end.
#ctrl-D
# Read the file
cat data/story.txt

# Patterns file used with grep -f
cat > data/patterns.txt
apple
banana
Line
#ctrl-D
# Read the file
cat data/patterns.txt

# ----------------------------------------------------------------------
# Create an instruction file for students
# ----------------------------------------------------------------------

#create a plain texh file INSTRUCTIONS.txt
touch scripts/INSTRUCTIONS.txt
# Read the file
cat scripts/INSTRUCTIONS.txt # It's be empty

#Practice exercises for basic Unix commands
#=========================================

#1. Printing text and variables
#-----------------------------
# Use `echo` and `printf` to print messages:
  echo "hello world"
  printf "hello world\n"

# Define a variable and print it.  Remember that assignment has no spaces:
  N=42
  echo $N        # prints 42
  printf $N"  # another way to print
#  case sensitive, no spaces around the equal sign, and you should
#  prefix a variable with `$` when reading it.

#2. Navigating directories
#-------------------------
# Show your current working directory with:
  pwd
# Change into the `data` directory you created and list its
#  contents, then return to the parent directory.  Recall that `.`
#  refers to the current directory, `..` to the parent and `~` to your home:
  cd data
  pwd
  cd ..

#3. Listing files and examining permissions
#-----------------------------------------
# List the contents of the current directory using different `ls`
  ls           # simple list
  ls -l        # long format showing permissions, ownership and size
  ls -a        # include hidden files
  ls -alh      # long format, including hidden files with human readable sizes
  ls data      # list contents of the data directory
  ls ..        # list contents of the parent directory

# Examine file permission:
  ls -l data/fruit.txt
#The nine characters after the first dash represent read (r), write (w) and execute (x) permissions for:
# owner, group and others.

#4. Creating files and directories
#--------------------------------
#  Use `mkdir` to create one or multiple directories.  For example,
#  create temporary directories inside your practice directory:
   mkdir tmp1 tmp2
   ls -l

#  Create a new file using `cat`.  This command will wait for
#  input.  Type some lines and finish with Ctrl‑D:

  cat > tmp/myfile.txt
  This is a new file created with cat
 # Ctrl-D
 # Read the file
  cat tmp/myfile.txt

# If you run cat with double >:
  cat >> tmp/myfile.txt
  Appending lines
  #ctrl-D
# The content will be appended instead of overwritten.
# Read the file
cat tmp/myfile.txt

# Alternatively you can use a text editor such as `nano` to create or edit files.  Try:
  nano tmp/myfile.txt
  #Then type some words like: "I am testing nano"
  #press Ctrl‑X, then Y and Enter to save

#5. Copying, moving and removing
#-------------------------------
# Copy `fruit.txt` to a new file and move it elsewhere:
 ls ./data
 cp data/fruit.txt data/fruit_copy.txt
 ls ./data
 mv data/fruit_copy.txt data/fruit_backup.txt   #renme the file 
 ls ./data
#   The `cp` command copies the contents of one file into another, and
#  `mv` moves or renames a file.

# Copy and move directories in the same way:
# ls commands below show how the content if ./data directory changes
  mkdir data/example_dir
  ls ./data/
  cp -r data/example_dir data/example_dir_copy
  ls ./data/
  mv data/example_dir_copy data/example_dir_moved
  ls ./data/

# Remove a file and a directory.  Be careful—`rm` permanently deletes files and directories:
 ls data
 rm data/fruit_backup.txt
 ls data
 rm -r data/example_dir_moved
 ls data
#You can use `rm -i -r` for interactive confirmation.

#6. Inspecting file contents
#---------------------------
# View the contents of a file one screen at a time using `less` or

  less data/story.txt
  more data/story.txt
# Use `q` to quit the viewer.

# Display the first and last few lines of a file with `head` and
# The `-n` option lets you specify how many lines to display【126210253433624†L418-L423】:
  head data/story.txt           # first 10 lines by default
  head -n 3 data/story.txt      # first 3 lines
  tail -n 2 data/story.txt      # last 2 lines

# Concatenate files using `cat`.  You can also print line numbers with `cat -n`:
  cat data/fruit.txt
  cat -n data/story.txt
  cat data/fruit.txt data/numbers.txt


#7. Counting with wc and using pipes
#-----------------------------------
# Count the number of lines, words and characters in a file using
  wc data/story.txt
  wc -l data/story.txt

# Use a pipe (`|`) to feed the output of one command into another.
# For example, count the number of lines returned by `cat`:
  cat data/story.txt | wc -l


#8. Redirecting output to a file
#-------------------------------
# Use the `>` operator to write output into a file instead of the terminal:
  cat data/fruit.txt data/numbers.txt > results/combined.txt
  head -n 3 data/story.txt > results/first3.txt

# 9. Sorting and deduplicating values
# -----------------------------------
# Sort the numbers and observe the difference between lexical and numeric sorting:
  sort data/numbers.txt     # lexical sort (1,10,11,2,3…)
  sort -n data/numbers.txt  # numeric sort
  sort -r data/numbers.txt  # reverse lexical sort

#Sort by a specific column in a CSV file using `-t` to set the delimiter and `-k` to choose the column:
  sort -t',' -k3 data/people.csv
  sort -t',' -k3,3 -n data/people.csv    # numeric sort on column 3

# Find unique lines with `uniq`.  The input must be sorted first:
  sort data/fruit.txt | uniq
  sort data/fruit.txt | uniq -c      # prefix lines with counts
  sort data/fruit.txt | uniq -d      # show duplicate lines

#10. Searching for patterns with grep
#------------------------------------
# Search for a simple pattern in a file:
 grep "banana" data/fruit.txt
 grep "banana" data/fruit.txt data/story.txt

#Use options to modify the behaviour:
  grep -i "apple" data/fruit.txt    # ignore case
  grep -w "apple" data/fruit.txt    # whole word match
  grep -v "banana" data/fruit.txt   # select non‑matching lines
  grep -n "apple" data/fruit.txt    # print line numbers
  grep -c "banana" data/fruit.txt   # count matches
  grep -f data/patterns.txt data/story.txt  # patterns from file

# Try regular expressions:
  grep "^Line" data/story.txt      # lines starting with 'Line'
  grep "\.txt$" -r .               # files ending with .txt in current tree
  grep "app.e" data/fruit.txt      # match appl*, one character between p and e

#11. Selecting columns with cut
#------------------------------
# Extract specific characters from each line:
 cut -c 1 data/fruit.txt       # first character of each line
 cut -c 1,5 data/story.txt     # first and fifth characters
 cut -c 1-4 data/fruit.txt     # first four characters
 cut -c 2- data/fruit.txt      # from second character to end
 cut -c -5 data/fruit.txt      # up to the fifth character

# Extract tab‑delimited columns from a file (for CSV files, set the delimiter using `-d`):
  cut -d ',' -f 1 data/people.csv       # first column
  cut -d ',' -f 1,3 data/people.csv     # first and third columns
  cut -d ',' -f 2-3 data/people.csv     # columns two to three
  cut -d ',' --complement -f 1 data/people.csv  # all except first column

# 12. Find and replace text with sed
# ----------------------------------
# Use `sed` to replace occurrences of a word:
 sed 's/apple/banana/1' data/fruit.txt    # replace first occurrence per line
 sed 's/apple/banana/2' data/fruit.txt    # replace second occurrence per line
 sed 's/apple/banana/g' data/fruit.txt    # replace all occurrences
 sed -i 's/banana/orange/g' data/fruit.txt  # in‑place replacement


# 13. Searching for files
# -----------------------
# Use `find` to search the directory tree:
  find . -name '*.txt'        # find all .txt files
  find . -type d             # list directories recursively
  find data -name 'n*'        # files starting with 'n' in data


# 14. Simple for loops
# --------------------
# Print the numbers 1 through 5:
  for i in {1..5}; do
    echo "Number: $i"
  done

# Iterate over all `.txt` files in the `data` directory and show their first two lines:
  for file in data/*.txt; do
    echo "--- $file ---"
    head -n 2 "$file"
  done

# Create multiple directories in a single loop:
  for d in trainA trainB trainC; do
    mkdir -p "$d"
  done
  ls -d train*/
  ```

# Copy all `.txt` files to `.bak` backups using parameter expansion:
  for file in data/*.txt; do
    cp "$file" "${file}.bak"
  done
