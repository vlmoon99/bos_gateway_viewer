import React, { useEffect, useState } from "react";
import { Widget } from "near-social-vm";
import { useLocation } from "react-router-dom";

function extractWidgetSrc(url) {
  const urlObj = new URL(url);
  const pathSegments = urlObj.pathname.split("/");
  const widgetSrcIndex = pathSegments.findIndex(
    (segment) => segment === "widget"
  );
  if (widgetSrcIndex !== -1 && widgetSrcIndex + 2 < pathSegments.length) {
    return `${pathSegments[widgetSrcIndex - 1]}/${
      pathSegments[widgetSrcIndex]
    }/${pathSegments[widgetSrcIndex + 1]}`;
  }
  return null;
}

export default function ViewPage(props) {
  const [src, setWidgetSrc] = useState(props.widgetSrc);
  const [widgetProps, setWidgetProps] = useState(props.widgetProps);

  const location = useLocation();

  useEffect(() => {
    console.log("URL changed to:", window.location.href);

    const params = new URLSearchParams(window.location.search);
    const newWidgetProps = { ...props.widgetProps };

    params.forEach((value, key) => {
      if (!["network", "widgetSrc", "accountId", "privateKey"].includes(key)) {
        newWidgetProps[key] = value;
      }
    });

    const newWidgetSrc = extractWidgetSrc(window.location.href);
    if (newWidgetSrc) {
      setWidgetSrc(newWidgetSrc);
    }

    setWidgetProps(newWidgetProps);

  }, [location]);

  return <Widget key={src} src={src} props={widgetProps} />;
}
