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

@include __PATH__+"/../Base.nut"

// BeforeTestCase
// Tests for MessageManager.beforeSend, MessageManager.beforeRetry
class BeforeTestCase extends ImpTestCase {

    function setUp() {
        infoAboutSide();
    }

    function testBeforeSendEnqueue() {
        return Promise(function(resolve, reject) {
            local postpone = true;
            local mm = MessageManager({
                "firstMessageId":  msgId,
                "nextIdGenerator": msgIdGenerator
            });
            mm.beforeSend(function(msg, enqueue, drop) {
                if (postpone) {
                    postpone = false;
                    enqueue();
                }
            }.bindenv(this));
            mm.onReply(function(msg, response) {
                try {
                    assertDeepEqualWrap(BASIC_MESSAGE, response.data, ERR_REQ_RES_NOT_IDENTICAL);
                    resolve();
                } catch (ex) {
                    reject(ex);
                }
            }.bindenv(this));
            mm.onFail(function(msg, reason, retry) {
                reject("onFail handler called. Reason: " + reason);
            }.bindenv(this));
            mm.onTimeout(function(msg, wait, fail) {
                fail();
            }.bindenv(this));
            mm.send(MESSAGE_NAME, BASIC_MESSAGE);
        }.bindenv(this));
    }

    function testBeforeSendDrop() {
        return Promise(function(resolve, reject) {
            local counter = 0;
            local err = "Some kind of error";
            local mm = MessageManager({
                "firstMessageId":  msgId,
                "nextIdGenerator": msgIdGenerator
            });
            local send = function() {
                mm.send(MESSAGE_NAME, BASIC_MESSAGE);
            };
            mm.beforeSend(function(msg, enqueue, drop) {
                counter++;
                if (counter == 1) {
                    drop(false, err);
                }
            }.bindenv(this));
            mm.onReply(function(msg, response) {
                try {
                    assertDeepEqualWrap(BASIC_MESSAGE, response.data, ERR_REQ_RES_NOT_IDENTICAL);
                    assertGreater(counter, 1, "First message should have been dropped");
                    resolve();
                } catch (ex) {
                    reject(ex);
                }
            }.bindenv(this));
            mm.onFail(function(msg, reason, retry) {
                if (counter == 1) {
                    try {
                        assertDeepEqualWrap(err, reason, "Wrong reason provided");
                        send();
                    } catch (ex) {
                        reject(ex);
                    }
                } else {
                    reject("onFail handler called. Reason: " + reason);
                }
            }.bindenv(this));
            mm.onTimeout(function(msg, wait, fail) {
                fail();
            }.bindenv(this));
            send();
        }.bindenv(this));
    }

    function testBeforeRetrySkip() {
        return Promise(function(resolve, reject) {
            local ts = 0;
            local retryInterval = 2;
            local retryShift = 0;
            local attempt = 0;
            local mm = MessageManager({
                "firstMessageId":  msgId,
                "nextIdGenerator": msgIdGenerator,
                "retryInterval":   retryInterval
            });
            mm.beforeSend(function(msg, enqueue, drop) {
                enqueue();
            }.bindenv(this));
            mm.beforeRetry(function(msg, skip, drop) {
                try {
                    attempt++;
                    if (ts == 0) {
                        ts = time();
                    }
                    local shift = time() - ts;
                    switch (attempt) {
                        case 1: 
                            assertDeepEqualWrap(retryShift, shift, "Wrong retry interval");
                            retryShift += retryInterval;
                            skip(); 
                            break;
                        case 2:
                            assertDeepEqualWrap(retryShift, shift, "Wrong retry interval");
                            retryShift += retryInterval + 2;
                            skip(retryInterval + 2);
                            break;
                        case 3:
                            assertDeepEqualWrap(retryShift, shift, "Wrong retry interval");
                            drop();
                            resolve();
                            break;
                    }
                } catch (ex) {
                    reject(ex);
                }
            }.bindenv(this));
            mm.onFail(function(msg, reason, retry) {
                reject("onFail handler called. Reason: " + reason);
            }.bindenv(this));
            mm.onTimeout(function(msg, wait, fail) {
                fail();
            }.bindenv(this));
            mm.onReply(function(msg, response) {
                reject("onReply handler called");
            }.bindenv(this));
            mm.send(MESSAGE_NAME, BASIC_MESSAGE);
        }.bindenv(this));
    }

    function testBeforeRetryDrop() {
        return Promise(function(resolve, reject) {
            local message = 0;
            local mm = MessageManager({
                "firstMessageId":  msgId,
                "nextIdGenerator": msgIdGenerator
            });
            local send = function() {
                mm.send(MESSAGE_NAME, BASIC_MESSAGE);
            };
            mm.beforeSend(function(msg, enqueue, drop) {
                enqueue();
            }.bindenv(this));
            mm.beforeRetry(function(msg, skip, drop) {
                try {
                    message++;
                    switch (message) {
                        case 1:
                            drop();
                            send();
                            break;
                        case 2:
                            drop(false);
                            break;
                    }
                } catch (ex) {
                    reject(ex);
                }
            }.bindenv(this));
            mm.onFail(function(msg, reason, retry) {
                if (message == 2) {
                    resolve();
                } else {
                    reject("onFail handler called. Reason: " + reason);
                }
            }.bindenv(this));
            mm.onTimeout(function(msg, wait, fail) {
                fail();
            }.bindenv(this));
            mm.onReply(function(msg, response) {
                reject("onReply handler called");
            }.bindenv(this));
            send();
        }.bindenv(this));
    }
}
