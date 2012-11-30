package com.ijumboapp;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.concurrent.ExecutionException;

import org.apache.http.HttpResponse;
import org.apache.http.HttpStatus;
import org.apache.http.StatusLine;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.os.AsyncTask;

class RequestManager {
	
	public String get(String url) {
		RequestTask task = new RequestTask();
		task.execute(url);
		String title = "";
		try {
			title = task.get();
		} catch (InterruptedException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (ExecutionException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		return title;
	}
	
	// if either get function does not work return null
	public JSONObject getJSONObject(String url) throws JSONException {
		JSONObject jsonOBJ = null;
		try {
			jsonOBJ = new JSONObject(this.get(url));
		} catch (JSONException e) {}
		return jsonOBJ;
	}
	
	public JSONArray getJSONArray(String url) throws JSONException {
		JSONArray jsonArray = null;
		try {
			jsonArray = new JSONArray(this.get(url));
		} catch (JSONException e) {}
		return jsonArray;
	}
}

class RequestTask extends AsyncTask<String, String, String>{

    @Override
    protected String doInBackground(String... uri) {
        HttpClient httpclient = new DefaultHttpClient();
        HttpResponse response;
        String responseString = null;
        try {
            response = httpclient.execute(new HttpGet(uri[0]));
            StatusLine statusLine = response.getStatusLine();
            if(statusLine.getStatusCode() == HttpStatus.SC_OK){
                ByteArrayOutputStream out = new ByteArrayOutputStream();
                response.getEntity().writeTo(out);
                out.close();
                responseString = out.toString();
            } else{
                //Closes the connection.
                response.getEntity().getContent().close();
                throw new IOException(statusLine.getReasonPhrase());
            }
        } catch (ClientProtocolException e) {
            //TODO Handle problems..
        } catch (IOException e) {
            //TODO Handle problems..
        }
        return responseString;
    }

    @Override
    protected void onPostExecute(String result) {
        super.onPostExecute(result);
        //Do anything with response..
    }
}