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

@include "github:electricimp/MessageManager/MessageManager.lib.nut"
@include __PATH__+"/../Base.nut"

// ConstructorTestCase
// Tests for MessageManager constructor options
class ConstructorTestCase extends ImpTestCase {

    function setUp() {
        infoAboutSide();
    }

    // firstMessageId, nextIdGenerator
    function testMessageId() {
        return Promise(function(resolve, reject) {
            local messages = 0;
            local max_messages = 5;
            local mid = msgId;
            local midGenerator = function() {
                mid = mid * 2;
                return mid;
            };
            local mm = MessageManager({
                "firstMessageId":  mid,
                "nextIdGenerator": midGenerator
            });
            local send = function() {
                mm.send(MESSAGE_NAME, BASIC_MESSAGE);
            };
            mm.onReply(function(msg, response) {
                try {
                    messages++;
                    assertDeepEqualWrap(mid, response.id, "Wrong message id");
                    assertDeepEqualWrap(BASIC_MESSAGE, response.data, ERR_REQ_RES_NOT_IDENTICAL);
                    if (messages >= max_messages) {
                        resolve();
                    } else {
                        send(); 
                    }
                } catch (ex) {
                    reject(ex);
                }
            }.bindenv(this));
            send();
        }.bindenv(this));
    }

    // maxMessageRate
    function testMaxMessageRate() {
        return Promise(function(resolve, reject) {
            local maxMessageRate = 2;
            local messages_handled = 0;
            local messages_replied = 0;
            local messages_failed = 0;
            local mm = MessageManager({
                "firstMessageId":  msgId,
                "nextIdGenerator": msgIdGenerator,
                "maxMessageRate":  maxMessageRate
            });
            local check = function() {
                if (messages_handled >= maxMessageRate + 1) {
                    if (
                        messages_replied == maxMessageRate && 
                        messages_failed == maxMessageRate + 1 - messages_replied
                    ) {
                        resolve();
                    } else {
                        reject("Replied to " + messages_replied + " message(s) and " + messages_failed + " message(s) failed");
                    }
                }
            };
            mm.onReply(function(msg, response) {
                try {
                    assertDeepEqualWrap(BASIC_MESSAGE, response.data, ERR_REQ_RES_NOT_IDENTICAL);
                } catch (ex) {
                    reject(ex);
                }
                messages_handled++;
                messages_replied++;
                check();
            }.bindenv(this));
            mm.onFail(function(msg, reason, retry) {
                messages_handled++;
                messages_failed++;
                check();
            });
            mm.onTimeout(function(msg, wait, fail) {
                fail();
            });
            for (local i = 0; i < maxMessageRate + 1; i++) {
                mm.send(MESSAGE_NAME, BASIC_MESSAGE);
            }
        }.bindenv(this));
    }

    // retryInterval
    function testRetry() {
        return Promise(function(resolve, reject) {
            local ts = 0;
            local retryInterval = 2;
            local mm = MessageManager({
                "firstMessageId":  msgId,
                "nextIdGenerator": msgIdGenerator,
                "retryInterval":   retryInterval
            });
            mm.beforeSend(function(msg, enqueue, drop) {
                enqueue();
            }.bindenv(this));
            mm.beforeRetry(function(msg, skip, drop) {
                if (ts == 0) {
                    ts = time();
                    skip();
                } else {
                    local shift = time() - ts;
                    if (retryInterval == shift) {
                        resolve();
                    } else {
                        reject("Retry attempt called with wrong retry interval: " + shift + ", must be: " + retryInterval);
                    }
                    drop();
                }
            });
            mm.onFail(function(msg, reason, retry) {
                reject("onFail handler called. Reason: " + reason);
            });
            mm.onTimeout(function(msg, wait, fail) {
                fail();
            });
            mm.onReply(function(msg, response) {
                reject("onReply handler called");
            }.bindenv(this));
            mm.send(MESSAGE_NAME, BASIC_MESSAGE);
        }.bindenv(this));
    }

    // autoRetry, maxAutoRetries
    function testAutoRetry() {
        return Promise(function(resolve, reject) {
            local maxAutoRetries = 4;
            local messageTimeout = MESSAGE_WITH_DELAY_SLEEP - 1;
            local mm = MessageManager({
                "firstMessageId":  msgId,
                "nextIdGenerator": msgIdGenerator,
                "maxAutoRetries":  maxAutoRetries,
                "autoRetry":       true,
                "retryInterval":   2,
                "messageTimeout":  messageTimeout
            });
            mm.beforeRetry(function(msg, skip, drop) {
                local tries = msg.tries + 1; // start counting from one, not zero 
                if (tries >= maxAutoRetries) {
                    imp.wakeup(MESSAGE_WITH_DELAY_SLEEP + 1, function() {
                        try {
                            assertDeepEqualWrap(maxAutoRetries, tries, "There were more than maxAutoRetries tries made");
                            resolve();
                        } catch (ex) {
                            reject(ex);
                        }
                    }.bindenv(this));
                }
            }.bindenv(this));
            mm.onTimeout(function(msg, wait, fail) {
                fail();
            }.bindenv(this));
            mm.onReply(function(msg, response) {
                reject("onReply handler called");
            }.bindenv(this));
            mm.send(MESSAGE_WITH_DELAY, BASIC_MESSAGE);
        }.bindenv(this));
    }

    // messageTimeout
    function testMessageTimeout() {
        return Promise(function(resolve, reject) {
            local ts = 0;
            local messageTimeout = MESSAGE_WITH_DELAY_SLEEP - 1;
            local mm = MessageManager({
                "firstMessageId":  msgId,
                "nextIdGenerator": msgIdGenerator,
                "messageTimeout":  messageTimeout
            });
            mm.beforeSend(function(msg, enqueue, drop) {
                ts = time();
            }.bindenv(this));
            mm.onFail(function(msg, reason, retry) {
                reject("onFail handler called. Reason: " + reason);
            });
            mm.onReply(function(msg, response) {
                reject("onReply handler called");
            }.bindenv(this));
            mm.onTimeout(function(msg, wait, fail) {
                try {
                    local shift = time() - ts;
                    assertDeepEqualWrap(messageTimeout, shift, "Wrong message timeout");
                    resolve();
                } catch (ex) {
                    reject(ex);
                }
                fail();
            }.bindenv(this));
            mm.send(MESSAGE_WITH_DELAY, BASIC_MESSAGE);
        }.bindenv(this));
    }
}
