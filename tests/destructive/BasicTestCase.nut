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

//@include "github:electricimp/MessageManager/MessageManager.lib.nut"
@include __PATH__+"/../MessageManager.lib.nut"
@include __PATH__+"/../ConnectionManager.nut"
@include __PATH__+"/../Base.nut"
@include __PATH__+"/BaseDestructive.nut"

// BasicTestCase
// Destructive tests for MessageManager.send, MessageManager.on
class BasicTestCase extends ImpTestCase {

    function setUp() {
        infoAboutSide();
    }
    
    function testSend() {
        local execute = function(message) {
            return Promise(function(resolve, reject) {
                local mm = MessageManager();
                mm.onReply(function(msg, response) {
                    try {
                        assertDeepEqual(message, response.data, ERR_REQ_RES_IDENTICAL + ". " +
                                                                "Type: " + typeof response.data + ". " +
                                                                "Expected: '" + message + "'. " +
                                                                "Got: '" + response.data + "'.");
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
            [{"key": "value"}, function(){}], 
            function(){},
            EmptyClass(),
            "hello\0",
            {"key\0": "value"}
        ];

        return createTestAll(execute, options, "only_fails");
    }

    function testSendWithHandlers() {
        local execute = function(value) {
            return Promise(function(resolve, reject) {
                local mm = MessageManager();
                local acked = false;
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
                        assertEqual(BASIC_MESSAGE, response.data, ERR_REQ_RES_NOT_IDENTICAL);
                        resolve();
                    } catch (ex) {
                        reject(ex);
                    }
                }.bindenv(this));

                local handlers = {
                    "onTimeout": value,
                    "onFail": value,
                    "onAck": value,
                    "onReply": value
                };

                try {
                    mm.send(MESSAGE_NAME, BASIC_MESSAGE, handlers);
                } catch (ex) {
                    reject("Catch mm.send: " + ex);
                }
            }.bindenv(this));
        }.bindenv(this);

        local options = [
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

        return createTestAll(execute, options, "only_successes");
    }

    /* 
    // Agent Runtime Error: ERROR: comparison between '1' and 'bool'
    function testSendWithTimeout() {
        local execute = function(value) {
            return Promise(function(resolve, reject) {
                local messageTimeout = MESSAGE_WITH_DELAY_SLEEP - 1;
                local localMessageTimeout = function(){};
                local mm = MessageManager({
                    "messageTimeout": messageTimeout
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
                            assertEqual(MESSAGE_WITH_DELAY, msg.payload.name, "Wrong msg.payload.name: " + msg.payload.name);
                            assertEqual(BASIC_MESSAGE, msg.payload.data, "Wrong msg.payload.data: " + msg.payload.data);
                            resolve();
                        } catch (ex) {
                            reject(ex);
                        }
                        fail();
                    }.bindenv(this)
                };
                mm.send(MESSAGE_WITH_DELAY, BASIC_MESSAGE, handlers, value);
            }.bindenv(this));
        }.bindenv(this);

        local options = [
            null, 
            true, 
            "String", 
            [1, 2], 
            {"counter": "this"}, 
            blob(64), 
            function(){}, 
            EmptyClass()
        ];

        return createTestAll(execute, options, "only_successes");
    }
    */

    function testOn() {
        local execute = function(value) {
            return Promise(function(resolve, reject) {
                local mm = MessageManager();
                try {
                    mm.on(MESSAGE_DESTRUCTIVE_RESEND_RESPONSE, value);
                } catch (ex) {
                    reject("Catch mm.on: " + ex);
                }
                mm.onReply(function(msg, response) {
                    try {
                        assertDeepEqual("OK", response, ERR_REQ_RES_IDENTICAL + ". " +
                                                        "Type: " + typeof response + ". " +
                                                        "Expected: 'OK'. " +
                                                        "Got: '" + response + "'.");
                        resolve();
                    } catch (ex) {
                        reject(ex);
                    }
                }.bindenv(this));
                mm.send(MESSAGE_DESTRUCTIVE_RESEND, BASIC_MESSAGE);
            }.bindenv(this));
        }.bindenv(this);

        local options = [
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
            EmptyClass()
        ];

        return createTestAll(execute, options, "only_successes");
    }

    function testOnWithReturn() {
        local execute = function(value) {
            return Promise(function(resolve, reject) {
                local mm = MessageManager();
                mm.on(MESSAGE_DESTRUCTIVE_RESEND_RESPONSE, function(message, reply) {
                    reply("OK");
                    return value;
                }.bindenv(this));
                mm.onReply(function(msg, response) {
                    try {
                        assertDeepEqual("OK", response, ERR_REQ_RES_IDENTICAL + ". " +
                                                        "Type: " + typeof response + ". " +
                                                        "Expected: 'OK'. " +
                                                        "Got: '" + response + "'.");
                        resolve();
                    } catch (ex) {
                        reject(ex);
                    }
                }.bindenv(this));
                mm.send(MESSAGE_DESTRUCTIVE_RESEND, BASIC_MESSAGE);
            }.bindenv(this));
        }.bindenv(this);

        local options = [
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

        return createTestAll(execute, options, "only_successes");
    }
}
