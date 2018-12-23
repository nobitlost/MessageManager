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

// BasicTestCase
// Tests for MessageManager.send, MessageManager.on
class BasicTestCase extends ImpTestCase {

    function setUp() {
        infoAboutSide();
    }

    function testSend() {
        return Promise(function(resolve, reject) {
            local mm = MessageManager({
                "firstMessageId":  msgId,
                "nextIdGenerator": msgIdGenerator
            });
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
            });
            mm.onTimeout(function(msg, wait, fail) {
                fail();
            });
            mm.send(MESSAGE_NAME, BASIC_MESSAGE);
        }.bindenv(this));
    }

	function testSendDefault() {
        return Promise(function(resolve, reject) {
            local mm = MessageManager({
                "firstMessageId":  msgId,
                "nextIdGenerator": msgIdGenerator
            });
            mm.onReply(function(msg, response) {
                try {
                    assertDeepEqualWrap(DEFAULT_MESSAGE, response.data, ERR_REQ_RES_NOT_IDENTICAL);
                    resolve();
                } catch (ex) {
                    reject(ex);
                }
            }.bindenv(this));
            mm.onFail(function(msg, reason, retry) {
                reject("onFail handler called. Reason: " + reason);
            });
            mm.onTimeout(function(msg, wait, fail) {
                fail();
            });
            mm.send(MESSAGE_DEFAULT, DEFAULT_MESSAGE);
        }.bindenv(this));
    }

    function testSendExtended() {
        return Promise(function(resolve, reject) {
            local mm = MessageManager({
                "firstMessageId":  msgId,
                "nextIdGenerator": msgIdGenerator,
                "maxMessageRate": 12
            });
            local messages = [null, true, 0, 1, -1, 0.0, 4.2, blob(8), "some string", ["first", "second"], {"key": "value"}];
            local failed = false;
            local done = function(){
                if (failed) {
                    reject();
                } else {
                    resolve();
                }
            }
            local next;
            next = function(index) {
                if (index >= messages.len()) {
                    done();
                    return;
                }
                local message = messages[index];
                mm.onReply(function(msg, response) {
                    try {
                        assertDeepEqualWrap(message, response.data, ERR_REQ_RES_NOT_IDENTICAL);
                    } catch (ex) {
                        info(ex);
                        failed = true;
                    }
                    next(++index);
                }.bindenv(this));
                mm.onFail(function(msg, reason, retry) {
                    info("onFail handler called. Reason: " + reason);
                    failed = true;
                }.bindenv(this));
                mm.onTimeout(function(msg, wait, fail) {
                    fail();
                });
                mm.send(MESSAGE_NAME, message);
            };
            next(0);
        }.bindenv(this));
    }

    function testSendWithHandlers() {
        return Promise(function(resolve, reject) {
            local mm = MessageManager({
                "firstMessageId":  msgId,
                "nextIdGenerator": msgIdGenerator
            });
            local results = {
                "onAck": false,
                "onTimeout": false,
                "onFail": false,
                "onReply": false
            };
            mm.onAck(function(msg) {
                if (!results["onAck"]) {
                    reject("global onAck handler called before handlers.onAck");
                }
            }.bindenv(this));
            mm.onTimeout(function(msg, wait, fail) {
                if (!results["onTimeout"]) {
                    reject("global onTimeout handler called before handlers.onTimeout");
                }
            }.bindenv(this));
            mm.onFail(function(msg, reason, retry) {
                if (!results["onFail"]) {
                    reject("global onFail handler called before handlers.onFail");
                }
            }.bindenv(this));
            mm.onReply(function(msg, response) {
                if (!results["onReply"]) {
                    reject("global onReply handler called before handlers.onReply");
                }
            }.bindenv(this));
            local handlers = {
                "onAck": function(msg) {
                    if (!results["onAck"]) {
                        results["onAck"] = true;
                    }
                }.bindenv(this),
                "onTimeout": function(msg, wait, fail) {
                    if (!results["onTimeout"]) {
                        results["onTimeout"] = true;
                    }
                    fail();
                }.bindenv(this),
                "onFail": function(msg, reason, retry) {
                    if (!results["onFail"]) {
                        results["onFail"] = true;
                    }
                }.bindenv(this),
                "onReply": function(msg, response) {
                    if (!results["onReply"]) {
                        results["onReply"] = true;
                        try {
                            assertDeepEqualWrap(BASIC_MESSAGE, response.data, ERR_REQ_RES_NOT_IDENTICAL);
                            resolve();
                        } catch (ex) {
                            reject(ex);
                        }
                    }
                }.bindenv(this)
            };
            mm.send(MESSAGE_NAME, BASIC_MESSAGE, handlers);
        }.bindenv(this));
    }

    function testSendWithTimeout() {
        return Promise(function(resolve, reject) {
            local messageTimeout = MESSAGE_WITH_DELAY_SLEEP + 2;
            local localMessageTimeout = MESSAGE_WITH_DELAY_SLEEP - 1;
            local mm = MessageManager({
                "firstMessageId":  msgId,
                "nextIdGenerator": msgIdGenerator,
                "messageTimeout":  messageTimeout
            });
            local handlers = {
                "onReply": function(msg, response) {
                    reject("onReply handler called");
                }.bindenv(this),
                "onFail": function(msg, reason, retry) {
                    reject("onFail handler called. Reason: " + reason);
                }.bindenv(this),
                "onTimeout": function(msg, wait, fail) {
                    try {
                        assertDeepEqualWrap(MESSAGE_WITH_DELAY, msg.payload.name, "Wrong msg.payload.name");
                        assertDeepEqualWrap(BASIC_MESSAGE, msg.payload.data, "Wrong msg.payload.data");
                        resolve();
                    } catch (ex) {
                        reject(ex);
                    }
                    fail();
                }.bindenv(this)
            };
            mm.send(MESSAGE_WITH_DELAY, BASIC_MESSAGE, handlers, localMessageTimeout);
        }.bindenv(this));
    }

    function testSendWithMetadata() {
        return Promise(function(resolve, reject) {
            local mm = MessageManager({
                "firstMessageId":  msgId,
                "nextIdGenerator": msgIdGenerator
            });
            local metadata = {
                "first": 1,
                "second": 2
            };
            local handlers = {
                "onReply": function(msg, response) {
                    try {
                        assertDeepEqualWrap(metadata, msg.metadata, "Wrong msg.metadata");
                        resolve();
                    } catch (ex) {
                        reject(ex);
                    }
                }.bindenv(this),
                "onFail": function(msg, reason, retry) {
                    reject("onFail handler called. Reason: " + reason);
                }.bindenv(this),
                "onTimeout": function(msg, wait, fail) {
                    fail();
                }.bindenv(this)
            };
            mm.send(MESSAGE_NAME, BASIC_MESSAGE, handlers, null, metadata);
        }.bindenv(this));
    }
}
