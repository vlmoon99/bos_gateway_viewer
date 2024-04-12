import React, { useEffect, useState } from "react";
import { Widget } from "near-social-vm";

export default function ViewPage(props) {

  const src = props.widgetSrc;
  const injectedProps = props.widgetProps;

  return (
    <Widget key={src} src={src} props={injectedProps} />
  );
}
