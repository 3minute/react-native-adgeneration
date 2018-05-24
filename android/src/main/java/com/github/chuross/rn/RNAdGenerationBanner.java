package com.github.chuross.rn;

import android.content.Context;
import android.graphics.Rect;
import android.support.annotation.NonNull;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.uimanager.PixelUtil;
import com.facebook.react.uimanager.events.RCTEventEmitter;
import com.socdm.d.adgeneration.ADG;
import com.socdm.d.adgeneration.ADGConsts;
import com.socdm.d.adgeneration.ADGListener;


public class RNAdGenerationBanner extends FrameLayout {

    public static final String EVENT_TAG_ON_MEASURE = "event_on_measure";
    private String locationId;
    private ADG.AdFrameSize frameSize = ADG.AdFrameSize.SP;
    private ReactContext reactContext;
    private ADG adg;
    private Runnable measureRunnable = new Runnable() {
        @Override
        public void run() {
            int widthMeasureSpec = MeasureSpec.makeMeasureSpec(getWidth(), MeasureSpec.EXACTLY);
            int heightMeasureSpec = MeasureSpec.makeMeasureSpec(getHeight(), MeasureSpec.EXACTLY);
            measure(widthMeasureSpec, heightMeasureSpec);
            layout(getLeft(), getTop(), getRight(), getBottom());

            sendSizeChangedEvent(getWidth(), getHeight());
        }
    };

    public RNAdGenerationBanner(@NonNull Context context) {
        super(context);
        this.reactContext = (ReactContext) context;

        setLayoutParams(new FrameLayout.LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT));
    }

    public void setLocationId(String locationId) {
        this.locationId = locationId;

        Rect bannerRect = getBannerRect(frameSize);
        if (bannerRect == null) return;

        removeAllViews();

        adg = new ADG(getContext());
        adg.setLayoutParams(new ViewGroup.LayoutParams(bannerRect.width(), bannerRect.height()));
        adg.setLocationId(locationId);

        adg.setAdListener(new ADGListener() {
            @Override
            public void onReceiveAd() {
            }

            @Override
            public void onFailedToReceiveAd(ADGConsts.ADGErrorCode code) {
                super.onFailedToReceiveAd(code);

                switch (code) {
                    case EXCEED_LIMIT:
                    case NEED_CONNECTION:
                    case NO_AD:
                        break;
                    default:
                        adg.start();
                        break;
                }
            }
        });

        addView(adg);
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
        if (adg == null) throw new IllegalStateException("need before set locationId");

        ADG.AdFrameSize frameSize = bannerType != null ? ADG.AdFrameSize.valueOf(bannerType.toUpperCase()) : null;
        if (frameSize == null) return;

        this.frameSize = frameSize;
        adg.setAdFrameSize(frameSize);
    }

    public void load() {
        if (locationId == null) return;
        adg.start();
    }

    private Rect getBannerRect(ADG.AdFrameSize frameSize) {
        if (frameSize == null) return null;
        return new Rect(0, 0, (int) PixelUtil.toPixelFromDIP(frameSize.getWidth()), (int) PixelUtil.toPixelFromDIP(frameSize.getHeight()));
    }

    private void sendSizeChangedEvent(int width, int height) {
        WritableMap event = Arguments.createMap();
        event.putInt("width", width);
        event.putInt("height", height);

        sendEvent(EVENT_TAG_ON_MEASURE, event);
    }

    private void sendEvent(String eventTag, WritableMap event) {
        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(getId(), eventTag, event);
    }

}