package com.naman14.arcade;

import android.content.Context;
import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import com.nostra13.universalimageloader.core.DisplayImageOptions;
import com.nostra13.universalimageloader.core.ImageLoader;

import org.json.JSONArray;
import org.json.JSONException;


/**
 * Created by naman on 12/05/16.
 */
public class StylesAdapter extends RecyclerView.Adapter<StylesAdapter.ViewHolder> {

    JSONArray array;
    private Context context;

    public StylesAdapter(Context context, JSONArray array) {
        this.array = array;
        this.context = context;
    }

    @Override
    public ViewHolder onCreateViewHolder(ViewGroup parent,
                                         int viewType) {

        View itemLayoutView = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_style_images, parent, false);

        ViewHolder viewHolder = new ViewHolder(itemLayoutView);
        return viewHolder;
    }

    @Override
    public void onBindViewHolder(ViewHolder viewHolder, final int position) {


        try {
            viewHolder.foreground.setVisibility(View.VISIBLE);
            viewHolder.styleImage.setScaleType(ImageView.ScaleType.CENTER_CROP);
            DisplayImageOptions defaultOptions = new DisplayImageOptions.Builder()
                    .cacheInMemory(true).cacheOnDisk(true)
                    .build();
            viewHolder.styleName.setText(array.getJSONObject(position).getString("title"));
            ImageLoader.getInstance().displayImage(array.getJSONObject(position).getString("url"),
                    viewHolder.styleImage, defaultOptions);

        } catch (JSONException e) {
            e.printStackTrace();
        }


    }

    public class ViewHolder extends RecyclerView.ViewHolder {

        public TextView styleName;
        public ImageView styleImage;
        public View foreground;

        public ViewHolder(View itemLayoutView) {
            super(itemLayoutView);
            styleImage = (ImageView) itemLayoutView.findViewById(R.id.style_image);
            styleName = (TextView) itemLayoutView.findViewById(R.id.style_name);
            foreground = itemLayoutView.findViewById(R.id.foreground);
        }
    }

    @Override
    public int getItemCount() {
        return array.length();
    }


}
