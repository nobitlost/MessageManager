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

// CallbacksTestCase
// Tests for MessageManager.onFail MessageManager.onTimeout, MessageManager.onAck, MessageManager.onReply
class CallbacksTestCase extends ImpTestCase {

    function setUp() {
        infoAboutSide();
    }
    
    function testOnFail() {
        return Promise(function(resolve, reject) {
            local counter = 0;
            local mm = MessageManager({
                "firstMessageId":  msgId,
                "nextIdGenerator": msgIdGenerator
            });
            mm.onFail(function(msg, reason, retry) {
                try {
                    assertDeepEqualWrap(MESSAGE_WITH_NO_HANDLER, msg.payload.name, "Wrong msg.payload.name");
                    assertDeepEqualWrap(BASIC_MESSAGE, msg.payload.data, "Wrong msg.payload.data");
                    assertDeepEqualWrap(MM_ERR_NO_HANDLER, reason, "Wrong reason");
                    if (counter++ == 0) {
                        retry(1);
                    } else {
                        resolve();
                    }
                } catch (ex) {
                    reject(ex);
                }
            }.bindenv(this));
            mm.onReply(function(msg, response) {
                reject("onReply handler called");
            }.bindenv(this));
            mm.send(MESSAGE_WITH_NO_HANDLER, BASIC_MESSAGE);
        }.bindenv(this));
    }

    function testOnTimeout() {
        return Promise(function(resolve, reject) {
            local counter = 0;
            local ts = 0;
            local messageTimeout = 2;
            local messageTimeoutInc = 0;
            local mm = MessageManager({
                "firstMessageId":  msgId,
                "nextIdGenerator": msgIdGenerator,
                "messageTimeout":  messageTimeout
            });
            mm.onTimeout(function(msg, wait, fail) {
                try {
                    counter++;
                    assertDeepEqualWrap(MESSAGE_WITH_LONG_DELAY, msg.payload.name, "Wrong msg.payload.name");
                    assertDeepEqualWrap(BASIC_MESSAGE, msg.payload.data, "Wrong msg.payload.data");
                    if (ts == 0) {
                        ts = time();
                    }
                    local shift = time() - ts;
                    switch (counter) {
                        case 1:
                            assertDeepEqualWrap(messageTimeoutInc, shift, "Wrong message timeout(1)");
                            messageTimeoutInc += messageTimeout;
                            wait();
                            break;
                        case 2:
                            assertDeepEqualWrap(messageTimeoutInc, shift, "Wrong message timeout(2)");
                            local w8 = 2;
                            messageTimeoutInc += w8;
                            wait(w8);
                            break;
                        case 3:
                            assertDeepEqualWrap(messageTimeoutInc, shift, "Wrong message timeout(3)");
                            fail();
                            break;
                    }
                } catch (ex) {
                    reject(ex);
                }
            }.bindenv(this));
            mm.onFail(function(msg, reason, retry) {
                if (counter == 3) {
                    resolve();
                } else {
                    reject("onFail handler called. Reason: " + reason);
                }
            }.bindenv(this));
            mm.onReply(function(msg, response) {
                reject("onReply handler called");
            }.bindenv(this));
            mm.send(MESSAGE_WITH_LONG_DELAY, BASIC_MESSAGE);
        }.bindenv(this));
    }

    function testOnAck() {
        return Promise(function(resolve, reject) {
            local mm = MessageManager({
                "firstMessageId":  msgId,
                "nextIdGenerator": msgIdGenerator
            });
            mm.onFail(function(msg, reason, retry) {
                reject("onFail handler called. Reason: " + reason);
            }.bindenv(this));
            mm.onReply(function(msg, response) {
                reject("onReply handler called");
            }.bindenv(this));
            mm.onAck(function(msg) {
                try {
                    assertDeepEqualWrap(BASIC_MESSAGE, msg.payload.data, ERR_REQ_RES_NOT_IDENTICAL);
                    resolve();
                } catch (ex) {
                    reject(ex);
                }
            }.bindenv(this))
            mm.send(MESSAGE_WITHOUT_RESPONSE, BASIC_MESSAGE);
        }.bindenv(this));
    }

    function testOnReply() {
        return Promise(function(resolve, reject) {
            local mm = MessageManager({
                "firstMessageId":  msgId,
                "nextIdGenerator": msgIdGenerator
            });
            mm.onReply(function(msg, response) {
                try {
                    assertDeepEqualWrap(BASIC_MESSAGE, response.data, ERR_REQ_RES_NOT_IDENTICAL);
                    assertDeepEqualWrap(BASIC_MESSAGE, msg.payload.data, ERR_REQ_RES_NOT_IDENTICAL);
                    resolve();
                } catch (ex) {
                    reject(ex);
                }
            }.bindenv(this));
            mm.send(MESSAGE_NAME, BASIC_MESSAGE);
        }.bindenv(this));
    }
}
