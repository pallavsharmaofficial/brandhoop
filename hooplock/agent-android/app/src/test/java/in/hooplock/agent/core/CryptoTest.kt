package `in`.hooplock.agent.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Fixtures produced by the server's signState / smsCommand, so both sides must agree byte for byte. */
class CryptoTest {
    private val key = "00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff"
    private val id = "11111111-2222-3333-4444-555555555555"
    private val payload = """{"v":1,"d":"11111111-2222-3333-4444-555555555555","s":7,"st":"locked","rel":false,"msg":"कृपया EMI भरें","shop":{"name":"Brand Hoop","phone":"9000000001"},"calls":["9000000001"],"dues":{"amount":2642,"overdueDays":12,"next":"2027-01-03","balance":10000},"upi":"upi://pay?pa=shop%40upi","ncl":1800000000,"loc":true,"t":1764000000}"""
    private val sig = "v448eoASslXVJGpK8ma13YBcE8A0efj53CYuezazghU"

    @Test fun verifiesServerSignature() {
        assertTrue(Crypto.verifyState(key, payload, sig))
        assertFalse(Crypto.verifyState(key, payload.replace("locked", "unlocked"), sig))
        assertFalse(Crypto.verifyState(key.replace('0', '1'), payload, sig))
    }

    @Test fun parsesState() {
        val s = AgentState.parse(payload)
        assertEquals(7, s.seq)
        assertEquals(LockLevel.LOCKED, s.level)
        assertEquals(listOf("9000000001"), s.callNumbers)
        assertEquals(2642.0, s.dueAmount, 0.0)
        assertEquals("2027-01-03", s.nextDue)
        assertEquals("कृपया EMI भरें", s.message)
    }

    @Test fun noContactRuleRestricts() {
        val s = AgentState.parse(payload.replace("\"st\":\"locked\"", "\"st\":\"unlocked\""))
        assertEquals(LockLevel.UNLOCKED, s.effectiveLevel(1_700_000_000))
        assertEquals(LockLevel.RESTRICTED, s.effectiveLevel(1_800_000_001))
        assertEquals(LockLevel.LOCKED, AgentState.parse(payload).effectiveLevel(1_800_000_001))
    }

    @Test fun smsCommands() {
        assertEquals(8 to 'U', Crypto.parseSms(key, id, "HL1 8 U 78wZhZQWmTFzqqI7Ylg4RQ"))
        assertNull(Crypto.parseSms(key, id, "HL1 8 L 78wZhZQWmTFzqqI7Ylg4RQ"))
        assertNull(Crypto.parseSms(key, "other-device", "HL1 8 U 78wZhZQWmTFzqqI7Ylg4RQ"))
    }
}
