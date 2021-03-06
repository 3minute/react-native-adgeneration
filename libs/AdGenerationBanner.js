import React, { Component } from 'react';
import {
  requireNativeComponent,
  ViewPropTypes,
  UIManager,
  findNodeHandle,
} from 'react-native';
import PropTypes from 'prop-types';

const RNAdGenerationBanner = requireNativeComponent('RNAdGenerationBanner');

export default class AdGenerationBanner extends Component {
  constructor(props) {
    super(props);
    this.state = {
      bannerWidth: 0,
      bannerHeight: 0,
    };
  }

  componentDidMount() {
    // iOS側のpropsがcomponentDidMountよりも後に呼ばれるので遅延させる
    setTimeout(() => this.load());
  }

  componentWillMount() {
  }

  render() {
    return <RNAdGenerationBanner
      ref={ref => this._bannerView = ref}
      {...this.props}
      style={[this.props.style, this.state.style]}
      onMeasure={event => this._handleOnMeasure(event)}
      onTapAd={event => this._handleOnTapAd(event)}
      onReceiveAdFailed = {event => this._handleOnReceiveAdFailed(event)}
    />;
  }

  _handleOnReceiveAdFailed(event) {
    if(this.props.locationType == '2') {
      this.setState({
        style: { width:0, height:0 }
      });
    }
    if (this.props.onReceiveAdFailed) this.props.onReceiveAdFailed(event);
  }

  _handleOnMeasure(event) {
    const { width, height } = event.nativeEvent;
    this.setState({
      style: { width, height }
    });
    if (this.props.onMeasure) this.props.onMeasure(event);
  }
  
  _handleOnTapAd(event) {
    const { locationId } = event.nativeEvent;
    if (this.props.onTapAd) this.props.onTapAd(event);
  }

  load() {
    UIManager.dispatchViewManagerCommand(
      findNodeHandle(this._bannerView),
      UIManager.RNAdGenerationBanner.Commands.load,
      null,
    );
  }
}

AdGenerationBanner.propTypes = {
  ...ViewPropTypes,

  locationId: PropTypes.string,
  //1 : normal | 2 : article detail
  locationType: PropTypes.string,
  // sp|rect|large|tablet|free
  bannerType: PropTypes.string,

  // require as bannerType:free
  bannerWidth: PropTypes.number,
  bannerHeight: PropTypes.number,

  // layout measured event
  // (width, height)
  onMeasure: PropTypes.func,

  onReceiveAdFailed: PropTypes.func,

  //ad tap event
  onTapAd: PropTypes.func,

  // load ad
  load: PropTypes.func
};