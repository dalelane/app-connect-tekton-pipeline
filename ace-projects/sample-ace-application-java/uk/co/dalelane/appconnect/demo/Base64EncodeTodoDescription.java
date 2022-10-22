package uk.co.dalelane.appconnect.demo;

import java.util.Base64;

import com.ibm.broker.javacompute.MbJavaComputeNode;
import com.ibm.broker.plugin.MbElement;
import com.ibm.broker.plugin.MbException;
import com.ibm.broker.plugin.MbMessage;
import com.ibm.broker.plugin.MbMessageAssembly;
import com.ibm.broker.plugin.MbOutputTerminal;
import com.ibm.broker.plugin.MbUserException;

public class Base64EncodeTodoDescription extends MbJavaComputeNode {

    public void evaluate(MbMessageAssembly inAssembly) throws MbException {
        MbMessage inMessage = inAssembly.getMessage();
        MbMessageAssembly outAssembly = null;
        try {
            MbMessage outMessage = new MbMessage(inMessage);
            MbElement outputRoot = outMessage.getRootElement();
            
            // get the todo list item title
            MbElement titleElement = outputRoot.getFirstElementByPath("JSON/Data/title");
            String title = titleElement.getValueAsString();
            
            // prefix the title with an environment variable
            //  (just to demonstrate we have provided an env var)
            title = String.join(" ", 
            			System.getenv("TODO_TITLE_PREFIX"),
            			title);
            
            // encode it
            byte[] encodedBytes = Base64.getEncoder().encode(title.getBytes());
            String encodedTitle = new String(encodedBytes);
            
            // add the encoded title to the output message
    		titleElement.createElementAfter(MbElement.TYPE_NAME_VALUE, "encodedTitle", encodedTitle);
            
    		// prepare the output message to return
            outAssembly = new MbMessageAssembly(inAssembly, outMessage);
        } 
        catch (MbException e) {
            throw e;
        } 
        catch (RuntimeException e) {
            throw e;
        } 
        catch (Exception e) {
            throw new MbUserException(this, "evaluate()", "", "", e.toString(), null);
        }
        
        // write to the output terminal
        MbOutputTerminal out = getOutputTerminal("out");
        out.propagate(outAssembly);
    }
}
