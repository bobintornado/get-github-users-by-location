# Goal

Retrieve list of Github users by location, Singapore in this case

# Run

`ruby main.rb`, optionally add access token to speed up things by running `ruby main.rb YOUR_TOKEN`

Result will be dumped as json into current folder as a file named `users.json`

# Verification

Go to `https://github.com/search?utf8=%E2%9C%93&q=location%3Asingapore` for current user count

# Last Run Result

2017 May 8: 9975 users in Singapore

# Github API limitation

1. Only allow paging through first 1000 results per search
2. Has rate limiting

# Solution

1. Divide and Conquer: split searchs into smaller chunks, so that each search has less than 1000 results per search, but try dividing as few times as possible
2. Wait until rate limit is reset

# Implementation Details:

1. Use recursion to simplify logics and re-use codes
2. Do simple binary split

# Implementation Limitation

1. Assume Github API is always working
2. Assume good network condition from begining to end
3. Can't resume progress yet

# Possible Improvement

1. Add persistence 
2. Add state management
