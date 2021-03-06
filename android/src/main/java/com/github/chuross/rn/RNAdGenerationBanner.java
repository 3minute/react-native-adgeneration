package com.github.chuross.rn;

import android.annotation.TargetApi;
import android.app.Activity;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.Rect;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.GradientDrawable;
import android.os.AsyncTask;
import android.os.Build;
import android.support.annotation.NonNull;
import android.util.AttributeSet;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.uimanager.PixelUtil;
import com.facebook.react.uimanager.events.RCTEventEmitter;
import com.facebook.ads.AdChoicesView;
import com.facebook.ads.AdIconView;
import com.facebook.ads.MediaView;
import com.facebook.ads.NativeAd;
import com.socdm.d.adgeneration.ADG;
import com.socdm.d.adgeneration.ADGConsts;
import com.socdm.d.adgeneration.ADGListener;
import com.socdm.d.adgeneration.nativead.ADGInformationIconView;
import com.socdm.d.adgeneration.nativead.ADGMediaView;
import com.socdm.d.adgeneration.nativead.ADGNativeAd;
import com.socdm.d.adgeneration.nativead.ADGNativeAdOnClickListener;

import java.net.URL;
import java.util.ArrayList;
import java.util.List;


public class RNAdGenerationBanner extends FrameLayout {

    public static final String EVENT_TAG_ON_MEASURE = "onMeasure";
    public static final String EVENT_TAG_ON_TAP_AD = "onTapAd";
    public static final String EVENT_TAG_ON_RECEIVE_AD_FAILED = "onReceiveAdFailed";
    private ReactContext reactContext;
    private ADG adg;
    private int freeBannerWidth;
    private int freeBannerHeight;
    private String locationType;
    private Runnable measureRunnable = new Runnable() {
        @Override
        public void run() {
            int widthMeasureSpec = MeasureSpec.makeMeasureSpec(getWidth(), MeasureSpec.EXACTLY);
            int heightMeasureSpec = MeasureSpec.makeMeasureSpec(getHeight(), MeasureSpec.EXACTLY);
            measure(widthMeasureSpec, heightMeasureSpec);
            layout(getLeft(), getTop(), getRight(), getBottom());
        }
    };

    public RNAdGenerationBanner(@NonNull final Context context) {
        super(context);
        this.reactContext = (ReactContext) context;

        setLayoutParams(new LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT));

        adg = new ADG(getContext());
        refreshBannerLayoutParams(ADG.AdFrameSize.SP);
        adg.setUsePartsResponse(true);

        adg.setAdListener(new ADGListener() {
            @Override
            public void onReceiveAd() {
            }
            @Override
            public void onReceiveAd(Object o) {

                View view = null;
                if (o instanceof ADGNativeAd) {
                    ADGNativeAdView nativeAdView = new ADGNativeAdView(context, null, Integer.parseInt(locationType));
                    nativeAdView.setLocationId(adg.getLocationId());
                    nativeAdView.apply((ADGNativeAd) o);
                    view = nativeAdView;
                } else if (o instanceof NativeAd) {
                    FBNativeAdView nativeAdView = new FBNativeAdView(context, null, Integer.parseInt(locationType));
                    nativeAdView.setLocationId(adg.getLocationId());
                    nativeAdView.apply((NativeAd) o);
                    view = nativeAdView;
                }

                if (view != null) {
                    // ローテーション時に自動的にViewを削除します
                    adg.setAutomaticallyRemoveOnReload(view);

                    addView(view);
                }
            }
            @Override
            public void onFailedToReceiveAd(ADGConsts.ADGErrorCode code) {
                super.onFailedToReceiveAd(code);

                switch (code) {
                    case EXCEED_LIMIT:
                    case NEED_CONNECTION:
                    case NO_AD:
                        WritableMap event = Arguments.createMap();
                        event.putString("locationId", adg.getLocationId());
                        sendEvent(EVENT_TAG_ON_RECEIVE_AD_FAILED, event);
                        break;
                    default:
                        if (adg != null) adg.start();
                        break;
                }
            }
            @Override
            public void onClickAd() {
                sendOnTapAdEvent();
            }
        });

        addView(adg);
    }

    public void setLocationId(String locationId) {
        adg.setLocationId(locationId);
    }

    public void setLocationType(String locationType) {
        this.locationType = locationType;
    }

    @Override
    public void requestLayout() {
        super.requestLayout();
        post(measureRunnable);
    }

    /**
     * @param bannerType sp|rect|tablet|large
     */
    public void setBannerType(String bannerType) {
        ADG.AdFrameSize frameSize = bannerType != null ? ADG.AdFrameSize.valueOf(bannerType.toUpperCase()) : null;
        if (frameSize == null) return;

        adg.setAdFrameSize(frameSize);
        if (bannerType.equalsIgnoreCase("FREE")){
            adg.setAdFrameSize(frameSize.setSize(freeBannerWidth,freeBannerHeight));
        }
        refreshBannerLayoutParams(frameSize);
    }

    public void setBannerWidth(int bannerWidth) {
        freeBannerWidth = bannerWidth;
    }

    public void setBannerHeight(int bannerHeight) {
        freeBannerHeight = bannerHeight;
    }

    public void load() {
        if (adg != null) adg.start();
    }

    public void destroy() {
        if (adg != null) adg.stop();
        adg = null;
    }

    private Rect getBannerRect(ADG.AdFrameSize frameSize) {
        if (frameSize == null) return null;
        return new Rect(0, 0, (int) PixelUtil.toPixelFromDIP(frameSize.getWidth()), (int) PixelUtil.toPixelFromDIP(frameSize.getHeight()));
    }

    private void refreshBannerLayoutParams(ADG.AdFrameSize frameSize) {
        Rect bannerRect = getBannerRect(frameSize);
        adg.setLayoutParams(new LayoutParams(bannerRect.width(), bannerRect.height()));

        sendSizeChangedEvent(frameSize);
    }

    private void sendSizeChangedEvent(ADG.AdFrameSize frameSize) {
        WritableMap event = Arguments.createMap();
        event.putInt("width", frameSize.getWidth());
        event.putInt("height", frameSize.getHeight());

        sendEvent(EVENT_TAG_ON_MEASURE, event);
    }

    private void sendEvent(String eventTag, WritableMap event) {
        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(getId(), eventTag, event);
    }

    public void sendOnTapAdEvent() {
        WritableMap event = Arguments.createMap();
        event.putString("locationId", adg.getLocationId());
        sendEvent(EVENT_TAG_ON_TAP_AD, event);
    }

}

class ADGNativeAdView extends RelativeLayout {

    private Context mContext;
    private Activity mActivity;
    private RelativeLayout mContainer;
    private ImageView mIconImageView;
    private TextView mTitleLabel;
    private TextView mBodyLabel;
    private TextView mDescLabel;
    private FrameLayout mMediaViewContainer;
    private TextView mSponsoredLabel;
    private TextView mCTALabel;
    private String mLocationId;
    private int mLocationType;
    private ReactContext mReactContext;

    public ADGNativeAdView(Context context) {
        this(context, null);
    }

    public ADGNativeAdView(Context context, AttributeSet attrs) {
        this(context, attrs, 0);
    }

    public ADGNativeAdView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init(context, attrs, defStyleAttr, 0);
    }

    @TargetApi(21)
    public ADGNativeAdView(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
        init(context, attrs, defStyleAttr, 0);
    }

    private void init(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        mContext = context;
        if (context instanceof Activity) {
            mActivity = (Activity)context;
        }
        mLocationType = defStyleAttr;
        mReactContext = (ReactContext)context;
        View layout;

        if(mLocationType == 2) {
            layout         = LayoutInflater.from(context).inflate(R.layout.adg_ad_view_in_article, this);
            mBodyLabel          = (TextView) layout.findViewById(R.id.adg_nativead_view_body);
        }else {
            layout = LayoutInflater.from(context).inflate(R.layout.adg_ad_view, this);
        }
        mContainer = (RelativeLayout) layout.findViewById(R.id.adg_nativead_view_container);
        mIconImageView = (ImageView) layout.findViewById(R.id.adg_nativead_view_icon);
        mTitleLabel = (TextView) layout.findViewById(R.id.adg_nativead_view_title);
        mTitleLabel.setText("");
        mMediaViewContainer = (FrameLayout) layout.findViewById(R.id.adg_nativead_view_mediaview_container);
        mSponsoredLabel = (TextView) layout.findViewById(R.id.adg_nativead_view_sponsored);

        GradientDrawable borders = new GradientDrawable();
        borders.setColor(Color.WHITE);
        borders.setCornerRadius(10);

    }

    public void setLocationId(String locationId) {
        mLocationId = locationId;
    }

    public void apply(ADGNativeAd nativeAd) {

        // アイコン画像
        if (nativeAd.getIconImage() != null) {
            String url = nativeAd.getIconImage().getUrl();
            new DownloadImageAsync(mIconImageView).execute(url);
        }

        // タイトル
        if (nativeAd.getTitle() != null) {
            mTitleLabel.setText(nativeAd.getTitle().getText());
        }

        // 本文
        if(mBodyLabel != null) {
            mBodyLabel.setText(nativeAd.getDesc().getValue());
        }

        // メイン画像・動画
        if (nativeAd.canLoadMedia()) {
            ADGMediaView mediaView = new ADGMediaView(mActivity);
            mediaView.setAdgNativeAd(nativeAd);
            mMediaViewContainer.addView(mediaView, new LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
            mediaView.load();
        }

        // インフォメーションアイコン
        ADGInformationIconView infoIcon = new ADGInformationIconView(getContext(), nativeAd);
        mMediaViewContainer.addView(infoIcon);

        // 広告主
        if (nativeAd.getSponsored() != null) {
            mSponsoredLabel.setText(nativeAd.getSponsored().getValue());
        } else {
            mSponsoredLabel.setText("sponsored");
        }

        ADGNativeAdOnClickListener listener;

        // クリックイベント
        nativeAd.setClickEvent(getContext(), mContainer, new ADGNativeAdOnClickListener() {
            @Override
            public void onClickAd() {
                super.onClickAd();
                WritableMap event = Arguments.createMap();
                event.putString("locationId", mLocationId);
                mReactContext.getJSModule(RCTEventEmitter.class).receiveEvent(getId(), RNAdGenerationBanner.EVENT_TAG_ON_TAP_AD, event);
            }
        });
    }

    /**
     * 画像をロードします(方法については任意で行ってください)
     */
    private class DownloadImageAsync extends AsyncTask<String, Void, Bitmap> {
        private ImageView imageView;

        public DownloadImageAsync(ImageView imageView) {
            this.imageView = imageView;
        }

        @Override
        protected Bitmap doInBackground(String... params) {
            try {
                String imageUrl = params[0];
                return BitmapFactory.decodeStream(new URL(imageUrl).openStream());
            } catch (Exception e) {
                e.printStackTrace();
            }
            return null;
        }

        @Override
        protected void onPostExecute(Bitmap bitmap) {
            this.imageView.setImageBitmap(bitmap);
        }
    }
}

class FBNativeAdView extends RelativeLayout {

    private Context mContext;
    private View mContainer;
    private AdIconView mIconImageView;
    private RelativeLayout mMediaViewContainer;
    private TextView mSocialContextLabel;
    private TextView mTitleLabel;
    private TextView mCtaLabel;
    private TextView mBodyLabel;
    private String mLocationId;
    private int mLocationType;
    private ReactContext mReactContext;

    public FBNativeAdView(Context context) {
        this(context, null);
    }

    public FBNativeAdView(Context context, AttributeSet attrs) {
        this(context, attrs, 0);
    }

    public FBNativeAdView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init(context, attrs, defStyleAttr, 0);
    }

    @TargetApi(21)
    public FBNativeAdView(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
        init(context, attrs, defStyleAttr, 0);
    }

    private void init(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        mContext = context;
        mReactContext = (ReactContext)context;
        View layout;
        mLocationType = defStyleAttr;
        if(mLocationType == 2) {
            layout         = LayoutInflater.from(context).inflate(R.layout.adg_fb_ad_view_in_article, this);
            mBodyLabel          = (TextView) layout.findViewById(R.id.adg_nativead_view_body);
            mCtaLabel           = (TextView) layout.findViewById(R.id.adg_nativead_view_cta);
        }else {
            layout         = LayoutInflater.from(context).inflate(R.layout.adg_fb_ad_view, this);
        }
        mContainer          = layout.findViewById(R.id.adg_nativead_view_container);
        mIconImageView      = (AdIconView) layout.findViewById(R.id.adg_nativead_view_icon);
        mMediaViewContainer = (RelativeLayout) layout.findViewById(R.id.adg_nativead_view_mediaview_container);
        mTitleLabel         = (TextView) layout.findViewById(R.id.adg_nativead_view_title);
        mSocialContextLabel = (TextView) layout.findViewById(R.id.adg_nativead_view_sponsored);

        mTitleLabel.setText("");
        mSocialContextLabel.setText("");
    }

    public void setLocationId(String locationId) {
        mLocationId = locationId;
    }

    public void apply(NativeAd nativeAd) {
        // MediaView
        MediaView mediaView = new MediaView(mContext);
        mMediaViewContainer.addView(mediaView);

        // タイトル
        mTitleLabel.setText(nativeAd.getAdHeadline());

        // ソーシャルコンテキスト
        mSocialContextLabel.setText(nativeAd.getAdSocialContext());

        // 本文
        if(mBodyLabel != null) {
            mBodyLabel.setText(nativeAd.getAdBodyText());
        }

        //cta
        if(mCtaLabel != null) {
            mCtaLabel.setText(nativeAd.getAdCallToAction());
        }

        // AdChoice
        AdChoicesView adChoicesView = new AdChoicesView(mContext, nativeAd, true);
        RelativeLayout.LayoutParams layoutParams = (RelativeLayout.LayoutParams) adChoicesView.getLayoutParams();
        layoutParams.addRule(ALIGN_PARENT_TOP);
        layoutParams.addRule(ALIGN_PARENT_RIGHT);
        mMediaViewContainer.addView(adChoicesView, layoutParams);

        //クリックイベント
        List<View> clickableViews = new ArrayList<>();
        clickableViews.add(mTitleLabel);
        clickableViews.add(mSocialContextLabel);

        nativeAd.registerViewForInteraction(mContainer, mediaView, mIconImageView, clickableViews);
        nativeAd.setOnTouchListener(new OnTouchListener() {
            @Override
            public boolean onTouch(View v, MotionEvent event) {
                WritableMap sendEvent = Arguments.createMap();
                sendEvent.putString("locationId", mLocationId);
                mReactContext.getJSModule(RCTEventEmitter.class).receiveEvent(getId(), RNAdGenerationBanner.EVENT_TAG_ON_TAP_AD, sendEvent);
                return false;
            }
        });
    }
}
