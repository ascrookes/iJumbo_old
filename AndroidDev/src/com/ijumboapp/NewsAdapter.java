package com.ijumboapp;

import org.json.JSONObject;

import android.app.Activity;
import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.ImageView;
import android.widget.TextView;

public class NewsAdapter extends ArrayAdapter<JSONObject> {

	Context context;
	int resourceID;
	Article[] data;
	
	public NewsAdapter(Context context, int textViewResourceId, Article[] objects) {
		super(context, textViewResourceId);
		this.data = objects;
		this.context = context;
		this.resourceID = textViewResourceId;
	}


	 @Override
	 public View getView(int position, View convertView, ViewGroup parent) {
		 View cell = convertView;
		 Holder holder = null;
		 if(cell == null) {
			 	LayoutInflater inflater = ((Activity)context).getLayoutInflater();
	            cell = inflater.inflate(this.resourceID, parent, false);
	            
	            holder = new Holder();
	            holder.textV = (TextView) cell.findViewById(R.id.txtTitleNews);
	            holder.imageV = (ImageView) cell.findViewById(R.id.imgIconNews);
	            
	            cell.setTag(holder);
		 } else {
			 holder = (Holder) cell.getTag();
		 }
		 
		 holder.textV.setText(data[position].toString());
		 holder.imageV.setImageBitmap(data[position].imageBitmap);

		 return cell;
	 }
	 
	static class Holder {
		TextView textV;
		ImageView imageV;
	}
	
	@Override
	public int getCount() {
		return this.data.length;
	}	
}