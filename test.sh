#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' 

PASS_COUNT=0
FAIL_COUNT=0
TOTAL_TESTS=0

run_test() {
    local category=$1
    local opts=$2
    local expected=$3
    ((TOTAL_TESTS++))

    raw_output=$(./aurobool $opts 2>&1)

    actual=$(echo "$raw_output" | sed 's/^> //' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    expected_trim=$(echo "$expected" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

    pass=0
    if [ "$actual" == "$expected_trim" ]; then
        pass=1
    elif [[ "$actual" != Error:* && "$expected_trim" != Error:* ]]; then
        eq_out=$(./aurobool --eq "$actual, $expected_trim" 2>/dev/null | tr -d '[:space:]')
        if [ "$eq_out" == "1" ]; then
            pass=1
        fi
    fi

    if [ $pass -eq 1 ]; then
        printf " ${GREEN}✔${NC} [${category}] ./aurobool %-30s -> ${GREEN}%s${NC}\n" "$opts" "$actual"
        ((PASS_COUNT++))
    else
        printf " ${RED}✘${NC} [${category}] ./aurobool %-30s\n" "$opts"
        printf "     ${YELLOW}Expected:${NC} '%s'\n" "$expected_trim"
        printf "     ${RED}Actual:  ${NC} '%s'\n" "$actual"
        ((FAIL_COUNT++))
    fi
}

run_test "SIMP" "-s \"A(A+B)\"" "A"
run_test "SIMP" "-s \"AB + A'C + BC\"" "AB+CA'"
run_test "SIMP" "-s \"A + A'BC + B'C\"" "A+C" 
run_test "SIMP" "-s \"(A + B' + (CD)')'\"" "A'BCD"
run_test "SIMP" "-s \"A ^ A\"" "0"

run_test "SOP " "--sop \"(A+B)(A+C)\"" "A'BC+AB'C'+AB'C+ABC'+ABC"
run_test "POS " "--pos \"AB + C\"" "(A+C)(B+C)"

run_test "EQUIV" "--eq \"A(B+C), AB+AC\"" "1"
run_test "EQUIV" "--eq \"A ^ B, (A+B)(AB)'\"" "1"
run_test "EQUIV" "--eq \"A, B\"" "0"

run_test "EDGE" "-s \"1 + 0 + A'A\"" "1"
run_test "EDGE" "-s \"A + () + #\"" "Error: Failed to parse expression."

echo -e "${BLUE}==================================================${NC}"
if [ $FAIL_COUNT -eq 0 ]; then
    printf "${GREEN}ALL TESTS PASSED! ($PASS_COUNT/$TOTAL_TESTS)${NC}\n"
else
    printf "${RED}SOME TESTS FAILED!${NC}\n"
    printf "${GREEN}Passed: %d${NC}\n" $PASS_COUNT
    printf "${RED}Failed: %d${NC}\n" $FAIL_COUNT
fi
echo -e "${BLUE}==================================================${NC}"

[ $FAIL_COUNT -eq 0 ] || exit 1
