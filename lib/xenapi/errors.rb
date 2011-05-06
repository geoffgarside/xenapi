module XenApi #:nodoc:
  module Errors #:nodoc:
    class GenericError < RuntimeError; end
    class BootloaderFailed < GenericError; end
    class DeviceAlreadyDetached < GenericError; end
    class DeviceDetachRejected < GenericError; end
    class EventsLost < GenericError; end
    class HAOperationWouldBreakFailoverPlan < GenericError; end
    class HostNameInvalid < GenericError; end
    class HostNotEnoughFreeMemory < GenericError; end
    class IsTunnelAccessPIF < GenericError; end
    class JoiningHostCannotContainSharedSRs < GenericError; end
    class LicenceRestriction < GenericError; end
    class LicenseProcessingError < GenericError; end
    class NoHostsAvailable < GenericError; end
    class OpenvswitchNotActive < GenericError; end
    class OperationNotAllowed < GenericError; end
    class OtherOperationInProgress < GenericError; end
    class PIFIsPhysical < GenericError; end
    class PIFTunnelStillExists < GenericError; end
    class SessionAuthenticationFailed < GenericError; end
    class SessionNotRegistered < GenericError; end
    class SRFull < GenericError; end
    class SRHasPDB < GenericError; end
    class SROperationNotSupported < GenericError; end
    class SRUnknownDriver < GenericError; end
    class TransportPIFNotConfigured < GenericError; end
    class UnknownBootloader < GenericError; end
    class VBDIsEmpty < GenericError; end
    class VBDNotEmpty < GenericError; end
    class VBDNotRemovableMedia < GenericError; end
    class VlanTagInvalid < GenericError; end
    class VMBadPowerState < GenericError; end
    class VMCheckpointResumeFailed < GenericError; end
    class VMCheckpointSuspendFailed < GenericError; end
    class VMHvmRequired < GenericError; end
    class VMIsTemplate < GenericError; end
    class VMMigrateFailed < GenericError; end
    class VMMissingPVDrivers < GenericError; end
    class VMRequiresSR < GenericError; end
    class VMRevertFailed < GenericError; end
    class VMSnapshotWithQuiesceFailed < GenericError; end
    class VMSnapshotWithQuiesceNotSupported < GenericError; end
    class VMSnapshotWithQuiescePluginDoesNotRespond < GenericError; end
    class VMSnapshotWithQuiesceTimeout < GenericError; end

    # Returns the class for the exception appropriate for the error description given
    #
    # @param [String] desc ErrorDescription value from the API
    # @return [Class] Appropriate exception class for the given description
    def self.exception_class_from_desc(desc)
      case desc
      when 'BOOTLOADER_FAILED'
        BootloaderFailed
      when 'DEVICE_ALREADY_DETACHED'
        DeviceAlreadyDetached
      when 'DEVICE_DETACH_REJECTED'
        DeviceDetachRejected
      when 'EVENTS_LOST'
        EventsLost
      when 'HA_OPERATION_WOULD_BREAK_FAILOVER_PLAN'
        HAOperationWouldBreakFailoverPlan
      when 'HOST_NAME_INVALID'
        HostNameInvalid
      when 'HOST_NOT_ENOUGH_FREE_MEMORY'
        HostNotEnoughFreeMemory
      when 'IS_TUNNEL_ACCESS_PIF'
        IsTunnelAccessPIF
      when 'JOINING_HOST_CANNOT_CONTAIN_SHARED_SRS'
        JoiningHostCannotContainSharedSRs
      when 'LICENCE_RESTRICTION'
        LicenceRestriction
      when 'LICENSE_PROCESSING_ERROR'
        LicenseProcessingError
      when 'NO_HOSTS_AVAILABLE'
        NoHostsAvailable
      when 'OPENVSWITCH_NOT_ACTIVE'
        OpenvswitchNotActive
      when 'OPERATION_NOT_ALLOWED'
        OperationNotAllowed
      when 'OTHER_OPERATION_IN_PROGRESS'
        OtherOperationInProgress
      when 'PIF_IS_PHYSICAL'
        PIFIsPhysical
      when 'PIF_TUNNEL_STILL_EXISTS'
        PIFTunnelStillExists
      when 'SESSION_AUTHENTICATION_FAILED'
        SessionAuthenticationFailed
      when 'SESSION_NOT_REGISTERED'
        SessionNotRegistered
      when 'SR_FULL'
        SRFull
      when 'SR_HAS_PDB'
        SRHasPDB
      when 'SR_OPERATION_NOT_SUPPORTED'
        SROperationNotSupported
      when 'SR_UNKNOWN_DRIVER'
        SRUnknownDriver
      when 'TRANSPORT_PIF_NOT_CONFIGURED'
        TransportPIFNotConfigured
      when 'UNKNOWN_BOOTLOADER'
        UnknownBootloader
      when 'VBD_IS_EMPTY'
        VBDIsEmpty
      when 'VBD_NOT_EMPTY'
        VBDNotEmpty
      when 'VBD_NOT_REMOVABLE_MEDIA'
        VBDNotRemovableMedia
      when 'VLAN_TAG_INVALID'
        VlanTagInvalid
      when 'VM_BAD_POWER_STATE'
        VMBadPowerState
      when 'VM_CHECKPOINT_RESUME_FAILED'
        VMCheckpointResumeFailed
      when 'VM_CHECKPOINT_SUSPEND_FAILED'
        VMCheckpointSuspendFailed
      when 'VM_HVM_REQUIRED'
        VMHVMRequired
      when 'VM_IS_TEMPLATE'
        VMIsTemplate
      when 'VM_MIGRATE_FAILED'
        VMMigrateFailed
      when 'VM_MISSING_PV_DRIVERS'
        VMMissingPVDrivers
      when 'VM_REQUIRES_SR'
        VMRequiresSR
      when 'VM_REVERT_FAILED'
        VMRevertFailed
      when 'VM_SNAPSHOT_WITH_QUIESCE_FAILED'
        VMSnapshotWithQuiesceFailed
      when 'VM_SNAPSHOT_WITH_QUIESCE_NOT_SUPPORTED'
        VMSnapshotWithQuiesceNotSupported
      when 'VM_SNAPSHOT_WITH_QUIESCE_PLUGIN_DOES_NOT_RESPOND'
        VMSnapshotWithQuiescePluginDoesNotRespond
      when 'VM_SNAPSHOT_WITH_QUIESCE_TIMEOUT'
        VMSnapshotWithQuiesceTimeout      
      else
        GenericError
      end
    end
  end
end
