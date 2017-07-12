// MIT License
//
// Copyright 2017 Electric Imp
//
// SPDX-License-Identifier: MIT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
// "Promise" symbol is injected dependency from ImpUnit_Promise module,
// while class being tested can be accessed from global scope as "::Promise".

// createTestAll
// Create Promise for series of tests
// 
// @param {function} execute - Function to be executed
// @param {array} options - Array of options to be passed into 'execute' function 
// @param {string} type - The condition for the success of all tests (only_successes|only_fails)
// @param {boolean} log - Display each test results
// @return {Promise}
function createTestAll(execute, options, type = "only_successes", log = false) {
    return Promise(function(resolve, reject) {
        local length = options.len();
        local index = 0;
        local successes = 0;
        local fails = 0;
        local last_reason = null;
        local next;
        next = function() {
            try {
                switch (type) {
                    case "only_fails": {
                        if (successes > 0) {
                            reject("createTestAll resolved one of the tests, but 'type' was 'only_fails'");
                            return;
                        }
                        if (fails >= length) {
                            resolve();
                            return;
                        }
                        break;
                    }
                    case "only_successes": default: {
                        if (fails > 0) {
                            reject(last_reason);
                            return;
                        }
                        if (successes >= length) {
                            resolve();
                            return;
                        }
                        break;
                    }
                }
                local params = options[index++];
                execute(params)
                    .then(function(value) {
                        successes++;
                        if (log) {
                            info("Resolved test with params: " + params);
                        }
                    }.bindenv(this))
                    .fail(function(reason) {
                        fails++;
                        last_reason = reason;
                        if (log) {
                            info("Rejected test with params: " + params);
                            info("Reason: " + reason);
                        }
                    }.bindenv(this))
                    .finally(function(valueOrReason) {
                        imp.wakeup(0, next);
                    }.bindenv(this));
            } catch(ex) {
                reject("Unexpected error while execute series of tests: " + ex);
            }
        }.bindenv(this);
        next();
    }.bindenv(this));
}

class EmptyClass {
    constructor(){}
}

class DEST_OPTIONS {
    static ALL_TYPES = [
        null, 
        true, 
        0, 
        -1, 
        1, 
        13.37, 
        "String", 
        [1, 2], 
        {"counter": "this"}, 
        blob(64), 
        function(){},
        EmptyClass()
    ];
    static ALL_TYPES_WO_FUNCTION = [
        null, 
        true, 
        0, 
        -1, 
        1, 
        13.37, 
        "String", 
        [1, 2], 
        {"counter": "this"}, 
        blob(64)
    ];
    static WO_CONCATENATION = [
        true, 
        [1, 2], 
        {"counter": "this"}, 
        blob(64), 
        function(){},
        EmptyClass()
    ];
    static SPECIAL_FOR_DROP = [
        [null, null],
        [null, true],
        [0, 0],
        [false, 13.37],
        [null, "String"],
        [null, [1, 2]],
        [null, {"counter": "this"}],
        [null, blob(64)],
        [null, function(){}],
        [null, EmptyClass()]
    ];
}