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

@include __PATH__+"/BaseDestructive.nut"

// DestBasicTestCase
// Destructive tests for MessageManager.send, MessageManager.on
// MessageManager.send with wrong type of parameter 'timeout' leads to Runtime Error, so we omit this test
class DestBasicTestCase extends BaseDestructive {

    function setUp() {
        infoAboutSide();
    }
    
    function testSendWithNonSerializableMessage() {
        if (!isAgentSide()) {
            // Device Runtime Error: ERROR: skipped unserialisable data
            info("This test is not supported on the device-side, so we skip this test that running on the device");
            return Promise(function(resolve, reject) {
                local mm = MessageManager();
                resolve();
            });
        }
        local execute = function(message) {
            return Promise(function(resolve, reject) {
                local mm = MessageManager({
                    "firstMessageId":  msgId,
                    "nextIdGenerator": msgIdGenerator
                });
                mm.onReply(function(msg, response) {
                    try {
                        assertDeepEqualWrap(message, response.data, ERR_REQ_RES_IDENTICAL);
                        resolve();
                    } catch (ex) {
                        reject(ex);
                    }
                }.bindenv(this));
                try {
                    mm.send(MESSAGE_NAME, message);
                } catch (ex) {
                    reject("Catch mm.send: " + ex);
                }
            }.bindenv(this));
        }.bindenv(this);

        local options = [
            function(){},
            EmptyClass(),
            // Unexpected token ☺ in JSON at position 113
            //"\x00\x01",
            {"\x00\x01": "value"},
            [function(){}, {"\x00\x01": "value"}]
        ];

        return createTestAll(execute, options, "negative");
    }

    function testSendWithHandlers() {
        local execute = function(value) {
            return Promise(function(resolve, reject) {
                local acked = false;
                local mm = MessageManager({
                    "firstMessageId":  msgId,
                    "nextIdGenerator": msgIdGenerator
                });
                mm.onTimeout(function(msg, wait, fail) {
                    reject("onTimeout");
                }.bindenv(this));
                mm.onFail(function(msg, reason, retry) {
                    reject("onFail");
                }.bindenv(this));
                mm.onAck(function(msg) {
                    acked = true;
                }.bindenv(this));
                mm.onReply(function(msg, response) {
                    try {
                        assertTrue(acked, "Got reply before ack");
                        assertDeepEqualWrap(BASIC_MESSAGE, response.data, ERR_REQ_RES_NOT_IDENTICAL);
                        resolve();
                    } catch (ex) {
                        reject(ex);
                    }
                }.bindenv(this));
                try {
                    local handlers = {
                        "onTimeout": value,
                        "onFail": value,
                        "onAck": value,
                        "onReply": value
                    };
                    mm.send(MESSAGE_NAME, BASIC_MESSAGE, handlers);
                } catch (ex) {
                    reject("Catch mm.send: " + ex);
                }
            }.bindenv(this));
        }.bindenv(this);
        return createTestAll(execute, DEST_OPTIONS.ALL_TYPES_WO_FUNCTION, "positive");
    }

    function testOn() {
        local execute = function(value) {
            return Promise(function(resolve, reject) {
                local mm = MessageManager({
                    "firstMessageId":  msgId,
                    "nextIdGenerator": msgIdGenerator
                });
                try {
                    mm.on(MESSAGE_DESTRUCTIVE_RESEND_RESPONSE, value);
                } catch (ex) {
                    reject("Catch mm.on: " + ex);
                }
                mm.onReply(function(msg, response) {
                    try {
                        assertDeepEqualWrap("OK", response, ERR_REQ_RES_IDENTICAL);
                        resolve();
                    } catch (ex) {
                        reject(ex);
                    }
                }.bindenv(this));
                mm.send(MESSAGE_DESTRUCTIVE_RESEND, BASIC_MESSAGE);
            }.bindenv(this));
        }.bindenv(this);
        return createTestAll(execute, DEST_OPTIONS.ALL_TYPES_WO_FUNCTION, "positive");
    }

    function testOnWithReturn() {
        local execute = function(value) {
            return Promise(function(resolve, reject) {
                local mm = MessageManager({
                    "firstMessageId":  msgId,
                    "nextIdGenerator": msgIdGenerator
                });
                mm.on(MESSAGE_DESTRUCTIVE_RESEND_RESPONSE, function(message, reply) {
                    reply("OK");
                    return value;
                }.bindenv(this));
                mm.onReply(function(msg, response) {
                    try {
                        assertDeepEqualWrap("OK", response, ERR_REQ_RES_IDENTICAL);
                        resolve();
                    } catch (ex) {
                        reject(ex);
                    }
                }.bindenv(this));
                mm.send(MESSAGE_DESTRUCTIVE_RESEND, BASIC_MESSAGE);
            }.bindenv(this));
        }.bindenv(this);
        return createTestAll(execute, DEST_OPTIONS.ALL_TYPES, "positive");
    }
}
