import React from "react";
import { Outlet, useLocation, useNavigate } from "react-router-dom";
import Loading from "src/components/Loading";
import { useInfo } from "src/hooks/useInfo";

export function DefaultRedirect() {
  const { data: info } = useInfo();
  const location = useLocation();
  const navigate = useNavigate();

  React.useEffect(() => {
    // TODO: also check if alby access token is OK, otherwise we need to re-login
    if (!info || (info.running && info.unlocked && info.onboardingCompleted)) {
      return;
    }
    navigate("/");
  }, [info, location, navigate]);

  if (!info) {
    return <Loading />;
  }

  return <Outlet />;
}
