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

// OverflowTestCase
// Tests for MessageManager.send, MessageManager.on
class OverflowTestCase extends ImpTestCase {

    function setUp() {
        infoAboutSide();
    }

    function testFullReply() {
        local total = 500;
        local max_rate = 500;
        local wait = 0.01;
        return Promise(function(resolve, reject) {

            local fail = 0;
            local timeout = 0;
            local ack = 0;
            local reply = 0;
            local replyFailed = 0;

            local local_fail = 0;
            local local_timeout = 0;
            local local_ack = 0;
            local local_reply = 0;
            local local_replyFailed = 0;

            local beforeSend = 0;
            local beforeRetry = 0;

            local ts = 0;

            local check = function() {
                local summ = fail + timeout + (local_ack + local_reply + local_replyFailed) / 2;
                if (summ >= total) {
                    try {
                        assertDeepEqualWrap(0, fail, "fail != 0");
                        assertDeepEqualWrap(0, timeout, "timeout != 0");
                        assertDeepEqualWrap(0, replyFailed, "replyFailed != 0");

                        assertDeepEqualWrap(0, local_fail, "fail != 0");
                        assertDeepEqualWrap(0, local_timeout, "timeout != 0");
                        assertDeepEqualWrap(0, local_replyFailed, "replyFailed != 0");

                        assertDeepEqualWrap(0, ack, "ack != 0");
                        assertDeepEqualWrap(0, reply, "reply != 0");

                        assertDeepEqualWrap(total, local_ack, "ack != total");
                        assertDeepEqualWrap(total, local_reply + local_replyFailed, "reply != total");
                        assertDeepEqualWrap(total, summ, "summ != total");
                        assertDeepEqualWrap(total, beforeSend, "beforeSend != total");
                        assertDeepEqualWrap(0, beforeRetry, "beforeRetry");
                        info("Sent and received: " + total + " message(s). Time: " + (time() - ts) + " second(s)");
                        resolve();
                    } catch (ex) {
                        info("failed");
                        info("fail " + fail + " | " +
                             "timeout " + timeout + " | " +
                             "ack " + ack + " | " +
                             "reply " + reply + " | " +
                             "replyFailed " + replyFailed);
                        info("local_fail " + local_fail + " | " +
                             "local_timeout " + local_timeout + " | " +
                             "local_ack " + local_ack + " | " +
                             "local_reply " + local_reply + " | " +
                             "local_replyFailed " + local_replyFailed);
                        info("summ/total " + summ + "/" + total);
                        reject(ex);
                    }
                }
            }.bindenv(this);

            local mm = MessageManager({
                "firstMessageId":  msgId,
                "nextIdGenerator": msgIdGenerator,
                "maxMessageRate": max_rate
            });

            mm.onFail(function(msg, reason, retry) {
                fail++;
                check();
            }.bindenv(this));

            mm.onTimeout(function(msg, wait, fail) {
                timeout++;
                check();
            }.bindenv(this));

            mm.onAck(function(msg) {
                ack++;
                check();
            }.bindenv(this));

            mm.onReply(function(msg, response) {
                try {
                    assertDeepEqualWrap(BASIC_MESSAGE, response.data, ERR_REQ_RES_NOT_IDENTICAL);
                    reply++;
                } catch (ex) {
                    replyFailed++;
                }
                check();
            }.bindenv(this));

            mm.beforeSend(function(msg, enqueue, drop) {
                beforeSend++;
                check();
            }.bindenv(this));

            mm.beforeRetry(function(msg, skip, drop) {
                beforeRetry++;
                check();
            }.bindenv(this));

            local handlers = {
                "onFail": function(msg, reason, retry) {
                    local_fail++;
                    check();
                }.bindenv(this),
                "onTimeout": function(msg, wait, fail) {
                    local_timeout++;
                    check();
                }.bindenv(this),
                "onAck": function(msg) {
                    local_ack++;
                    check();
                }.bindenv(this),
                "onReply": function(msg, response) {
                    try {
                        assertDeepEqualWrap(BASIC_MESSAGE, response.data, ERR_REQ_RES_NOT_IDENTICAL);
                        local_reply++;
                    } catch (ex) {
                        local_replyFailed++;
                    }
                    check();
                }.bindenv(this)
            };

            ts = time();

            local send;
            send = function(index) {
                if (index < total) {
                    mm.send(MESSAGE_NAME, BASIC_MESSAGE, handlers);
                    imp.wakeup(wait, function() {
                        send(++index);
                    }.bindenv(this));
                } else {
                    check();
                }
            }.bindenv(this);
            send(0);
        }.bindenv(this));
    }

    function testDisconnectedDoesntSendMessages() {
        if (isAgentSide()) {
            info("ConnectionManager is a device-side only library, so we skip this test that running on the agent");
            return Promise(function(resolve, reject) {
                local mm = MessageManager();
                resolve();
            });
        }
        local TOTAL_OFFLINE_MESSAGE_COUNT = 10;
        return Promise(function(resolve, reject) {
            local _numOfAcks = 0;
            local _numOfFails = 0;
            local _numOfReplies = 0;
            local _numOfTimeouts = 0;
            local _numOfBeforeSends = 0;
            local _numOfBeforeRetries = 0;

            local _numOfLocalAcks = 0;
            local _numOfLocalFails = 0;
            local _numOfLocalReplies = 0;
            local _numOfLocalTimeouts = 0;

            local gOnAck = function(msg) {
                _numOfAcks++;
            }

            local gOnFail = function(msg, error, retry) {
                _numOfFails++;
                retry();
            }

            local gOnReply = function(msg, response) {
                _numOfReplies++;
            }

            local gOnTimeout = function(msg, wait, fail) {
                _numOfTimeouts++;
            }

            local gBeforeSend = function(msg, enqueue, drop) {
                _numOfBeforeSends++;
            }

            local gBeforeRetry = function(msg, skip, drop) {
                _numOfBeforeRetries++;
            }

            local localOnAck = function(msg) {
                _numOfLocalAcks++;
            }

            local localOnFail = function(msg, error, retry) {
                _numOfLocalFails++;
            }

            local localOnReply = function(msg, response) {
                _numOfLocalReplies++;
            }

            local localOnTimeout = function(msg, wait, fail) {
                _numOfLocalTimeouts++;
            }

            local _handlers = {};
            _handlers[MM_HANDLER_NAME_ON_ACK]     <- localOnAck.bindenv(this);
            _handlers[MM_HANDLER_NAME_ON_FAIL]    <- localOnFail.bindenv(this);
            _handlers[MM_HANDLER_NAME_ON_REPLY]   <- localOnReply.bindenv(this);
            _handlers[MM_HANDLER_NAME_ON_TIMEOUT] <- localOnTimeout.bindenv(this);

            local cm = getConnectionManager();
            local mm = MessageManager({
                "firstMessageId":    msgId,
                "nextIdGenerator":   msgIdGenerator,
                "messageTimeout":    10,
                "connectionManager": cm
            });
            mm.onAck(gOnAck.bindenv(this));
            mm.onFail(gOnFail.bindenv(this));
            mm.onReply(gOnReply.bindenv(this));
            mm.onTimeout(gOnTimeout.bindenv(this));
            mm.beforeSend(gBeforeSend.bindenv(this));
            mm.beforeRetry(gBeforeRetry.bindenv(this));

            // run

            cm.disconnect();

            for (local i = 0; i < TOTAL_OFFLINE_MESSAGE_COUNT; i++) {
                mm.send(MESSAGE_NAME, BASIC_MESSAGE);
            }

            imp.wakeup(2, function() {
                local pending = mm.getPendingCount();
                try {
                    assertDeepEqualWrap(0, _numOfAcks, "acks");
                    assertDeepEqualWrap(0, _numOfReplies, "replies");
                    assertDeepEqualWrap(0, _numOfTimeouts, "timeouts");
                    assertDeepEqualWrap(0, _numOfBeforeRetries, "beforeRetries");
                    assertDeepEqualWrap(TOTAL_OFFLINE_MESSAGE_COUNT, _numOfFails, "fails");
                    assertDeepEqualWrap(TOTAL_OFFLINE_MESSAGE_COUNT, _numOfBeforeSends, "beforeSends");
                    assertDeepEqualWrap(TOTAL_OFFLINE_MESSAGE_COUNT, pending, "pending");

                    // If both handlers are defined, the number of acks should be equal to the number of replies
                    assertDeepEqualWrap(_numOfReplies, _numOfAcks, "acks == replies");

                    // No local handlers to be called
                    assertDeepEqualWrap(0, _numOfLocalAcks, "localAcks");
                    assertDeepEqualWrap(0, _numOfLocalFails, "localFails");
                    assertDeepEqualWrap(0, _numOfLocalReplies, "localReplies");
                    assertDeepEqualWrap(0, _numOfLocalTimeouts, "localTimeouts");

                    resolve();
                } catch (ex) {
                    info("fails " + _numOfFails + " | " +
                         "timeouts " + _numOfTimeouts + " | " +
                         "acks " + _numOfAcks + " | " +
                         "replies " + _numOfReplies);
                    info("l_fails " + _numOfLocalFails + " | " +
                         "l_timeouts " + _numOfLocalTimeouts + " | " +
                         "l_acks " + _numOfLocalAcks + " | " +
                         "l_replies " + _numOfLocalReplies);
                    info("beforeRetries " + _numOfBeforeRetries + " | " +
                         "beforeSends " + _numOfBeforeSends + " | " +
                         "pending " + pending);
                    reject(ex);
                }
            }.bindenv(this));
        }.bindenv(this));
    }

    function testThrottlingDevice() {
        local MAX_RATE_LIMIT      = 17;
        local RETRY_INTERVAL_SEC  = 1;
        local TOTAL_MESSAGES_SENT = 33;
        return Promise(function(resolve, reject) {
            local _mm = null;
            local _numOfAcks = 0;
            local _numOfFailures = 0;

            local onAck = function(msg) {
                _numOfAcks++;
            }

            local onFail = function(msg, error, retry) {
                if (error == "Maximum sending rate exceeded") {
                    _numOfFailures++;
                }
            }

            local _send = function(name, data = null, handlers = null, timeout = null, metadata = null) {
                _mm.send(name, data, handlers, timeout, metadata);
            }

            _mm = MessageManager({
                "firstMessageId":  msgId,
                "nextIdGenerator": msgIdGenerator,
                "maxMessageRate" : MAX_RATE_LIMIT,
                "retryInterval"  : RETRY_INTERVAL_SEC
            });
            _mm.onAck(onAck.bindenv(this));
            _mm.onFail(onFail.bindenv(this));

            // Send all the messages offline
            for (local i = 0; i < TOTAL_MESSAGES_SENT; i++) {
                _send(MESSAGE_NAME, i);
                imp.sleep(0.01);
            }

            imp.wakeup(3, function() {
                try {
                    assertDeepEqualWrap(TOTAL_MESSAGES_SENT - MAX_RATE_LIMIT, _numOfFailures, "Number of rate limits");
                    assertDeepEqualWrap(MAX_RATE_LIMIT, _numOfAcks, "Number of ACKs");
                    resolve();
                } catch (ex) {
                    reject(ex);
                }
            }.bindenv(this));

        }.bindenv(this));
    }
}
