@isTest
public class SampleClass1test {

   public static testMethod void testMyClass(){
       String helloMessage = SampleClass1.helloMessage();
       System.assertEquals(helloMessage, 'Hello ,first sample class!');

   }
}