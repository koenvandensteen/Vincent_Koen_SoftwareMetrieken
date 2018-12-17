// total lines = 2 (import) + 3 (class level) + 7  = 12
// expected results: 20% of methods covered 2 asserts for CC 24 = 8.33% test coverage

import org.junit.Test;
import static org.junit.Assert.*;

public class UnitTest {

	// complexity: 1
	// lines: 7
    @Test
    public void testConcatenate() {
        SimpleJavaDemo demo = new SimpleJavaDemo();

        int result = demo.doeIetsAnders(0);
        assertEquals(0, result);
        result = demo.doeIetsAnders(10);
        assertEquals(20, result);
    }
}