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

const MESSAGE_NAME = "test";
const MESSAGE_WITHOUT_RESPONSE = "test_no_response";
const MESSAGE_WITH_DELAY = "test_with_delay";
const MESSAGE_WITH_HUGE_DELAY = "test_with_huge_delay";
const MESSAGE_DESTRUCTIVE_RESEND = "test_destructive_resend";
const MESSAGE_DESTRUCTIVE_RESEND_RESPONSE = "test_destructive_resend_response";

const REPLY_NO_MESSAGES = "No messages";
const BASIC_MESSAGE = "basic message";

const MESSAGE_WITH_DELAY_SLEEP = 2;
const MESSAGE_WITH_DELAY_DEEP_SLEEP = 16;

const ERR_REQ_RES_NOT_IDENTICAL = "Request and response messages are not identical";
const ERR_REQ_RES_IDENTICAL = "Request and response messages are identical";

function isAgentSide() {
    return imp.environment() == ENVIRONMENT_AGENT;
}

function infoAboutSide() {
    info("Tests will be performed on the " + (isAgentSide() ? "agent" : "device") + "-side");
}

function assertDeepEqualWrap(expected, actial, message = null, compare = false) {
    if (compare) {
        local compareString = "Type: " + typeof actial + ". " +
                              "Expected: '" + expected + "'. " +
                              "Got: '" + actial + "'.";
        if (message == null) {
            message = compareString;
        } else {
            message = message + ". " + compareString;
        }
    }
    assertDeepEqual(expected, actial, message);
}
