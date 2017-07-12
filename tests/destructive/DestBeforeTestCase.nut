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
@include __PATH__+"/../ConnectionManager.nut"
@include __PATH__+"/../Base.nut"
@include __PATH__+"/BaseDestructive.nut"

// DestBeforeTestCase
// Destructive tests for MessageManager.beforeSend, MessageManager.beforeRetry
class DestBeforeTestCase extends ImpTestCase {

    function setUp() {
        infoAboutSide();
    }

    function testBeforeSendWithReturn() {
        local execute = function(value) {
            return Promise(function(resolve, reject) {
                local mm = MessageManager({
                    "firstMessageId":  msgId,
                    "nextIdGenerator": msgIdGenerator
                });
                mm.beforeSend(function(msg, enqueue, drop) {
                    return value;
                }.bindenv(this));
                mm.onReply(function(msg, response) {
                    try {
                        assertDeepEqualWrap(BASIC_MESSAGE, response.data, ERR_REQ_RES_IDENTICAL);
                        resolve();
                    } catch (ex) {
                        reject(ex);
                    }
                }.bindenv(this));
                mm.send(MESSAGE_NAME, BASIC_MESSAGE);
            }.bindenv(this));
        }.bindenv(this);
        return createTestAll(execute, DEST_OPTIONS.ALL_TYPES, "only_successes");
    }

    function testBeforeSendDropWrongParams() {
        local execute = function(pair) {
            return Promise(function(resolve, reject) {
                local mm = MessageManager({
                    "firstMessageId":  msgId,
                    "nextIdGenerator": msgIdGenerator
                });
                mm.beforeSend(function(msg, enqueue, drop) {
                    try {
                        drop(pair[0], pair[1]);
                    } catch (ex) {
                        reject("Catch drop: " + ex);
                    }
                }.bindenv(this));
                mm.onFail(function(msg, reason, retry) {
                    try {
                        pair[1] != null && assertDeepEqualWrap(pair[1], reason, "Wrong reason provided");
                        resolve();
                    } catch (ex) {
                        reject(ex);
                    }
                }.bindenv(this));
                mm.send(MESSAGE_NAME, BASIC_MESSAGE);
            }.bindenv(this));
        }.bindenv(this);
        return createTestAll(execute, DEST_OPTIONS.SPECIAL_FOR_DROP, "only_successes");
    }

    function testBeforeRetryWithReturn() {
        local execute = function(value) {
            return Promise(function(resolve, reject) {
                local mm = MessageManager({
                    "firstMessageId":  msgId,
                    "nextIdGenerator": msgIdGenerator
                });
                mm.beforeRetry(function(msg, skip, drop) {
                    return value;
                }.bindenv(this));
                mm.onReply(function(msg, response) {
                    try {
                        assertDeepEqualWrap(BASIC_MESSAGE, response.data, ERR_REQ_RES_IDENTICAL);
                        resolve();
                    } catch (ex) {
                        reject(ex);
                    }
                }.bindenv(this));
                mm.send(MESSAGE_NAME, BASIC_MESSAGE);
            }.bindenv(this));
        }.bindenv(this);
        return createTestAll(execute, DEST_OPTIONS.ALL_TYPES, "only_successes");
    }

    function testBeforeRetrySkipWrongParams() {
        local execute = function(value) {
            return Promise(function(resolve, reject) {
                local counter = 0;
                local mm = MessageManager({
                    "firstMessageId":  msgId,
                    "nextIdGenerator": msgIdGenerator,
                    "retryInterval":   1
                });
                mm.beforeSend(function(msg, enqueue, drop) {
                    enqueue();
                }.bindenv(this));
                mm.beforeRetry(function(msg, skip, drop) {
                    try {
                        counter++;
                        switch (counter) {
                            case 1: 
                                skip(value);
                                break;
                            case 2:
                                drop();
                                resolve();
                                break;
                        }
                    } catch (ex) {
                        reject("Catch drop: " + ex);
                    }
                }.bindenv(this));
                mm.send(MESSAGE_NAME, BASIC_MESSAGE);
            }.bindenv(this));
        }.bindenv(this);
        return createTestAll(execute, DEST_OPTIONS.WO_CONCATENATION, "only_fails");
    }

    function testBeforeRetryDropWrongParams() {
        local execute = function(pair) {
            return Promise(function(resolve, reject) {
                local mm = MessageManager({
                    "firstMessageId":  msgId,
                    "nextIdGenerator": msgIdGenerator,
                    "retryInterval":   1
                });
                mm.beforeSend(function(msg, enqueue, drop) {
                    enqueue();
                }.bindenv(this));
                mm.beforeRetry(function(msg, skip, drop) {
                    try {
                        drop(pair[0], pair[1]);
                    } catch (ex) {
                        reject("Catch drop: " + ex);
                    }
                }.bindenv(this));
                mm.onFail(function(msg, reason, retry) {
                    try {
                        pair[1] != null && assertDeepEqualWrap(pair[1], reason, "Wrong reason provided");
                        resolve();
                    } catch (ex) {
                        reject(ex);
                    }
                }.bindenv(this));
                mm.send(MESSAGE_NAME, BASIC_MESSAGE);
            }.bindenv(this));
        }.bindenv(this);
        return createTestAll(execute, DEST_OPTIONS.SPECIAL_FOR_DROP, "only_successes");
    }
}
