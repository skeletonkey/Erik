package com.jundy;

public class Erik {
    private static Boolean printEnabled = true;

    public static void enable()  { printEnabled = false; }
    public static void disable() { printEnabled = false; }

    public static void explainByteArray(byte[] data) { explainByteArray(data, "Byte Data", 4); }
    public static void explainByteArray(byte[] data, String label) { explainByteArray(data, label, 4); }
    public static void explainByteArray(byte[] data, String label, Integer frameOffset) {
        StringBuffer sb = new StringBuffer();
        for (byte x : data) {
            if (sb.length() > 0) {
                sb.append(',').append(x);
            }
            else {
                sb.append(x);
            }
        }
        print(label + " :data: " + sb, frameOffset);
        print(label + " :string: " + new String(data), frameOffset);
    }


    public static void ping() { print("", 3); }
    public static void log(String data) { print(data, 3); }
    public static void print(String data) { print(data, 3); }
    private static void print(String data, Integer frameOffset) {
        StackTraceElement frame = Thread.currentThread().getStackTrace()[frameOffset];
        say(frame.getClassName() + " -- " + frame.getLineNumber() + ": " + data);
    }

    public static void method() {
        StackTraceElement frame = Thread.currentThread().getStackTrace()[2];
        say(frame.getClassName() + " -> " + frame.getMethodName());
    }

    public static void say(String data) {
        if (printEnabled) {
            System.out.println(data);
        }
    }
}


/*
Version info:
    Why list the version in the file itself?  So it's easier to see if you are current and I'm too lazy to do it any other way.
20170411 - First check in

 */
